import 'dart:async';
import 'dart:convert' as json;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:web/web.dart' as import_web;
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_journal_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_bulk_update_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_export_current_view_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_export_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_attachment_card_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_generated_pdf_preview_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_mileage_indicator_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expenses_more_menu_widgets.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expenses_filter_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/providers/expenses_provider.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/create_recurring_expense_request.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/recurring_expense_details_model.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/recurring_expense_enums.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/providers/recurring_expense_provider.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class ExpensesOverview extends ConsumerStatefulWidget {
  final String expenseId;
  const ExpensesOverview({super.key, required this.expenseId});

  @override
  ConsumerState<ExpensesOverview> createState() => _ExpensesOverviewState();
}

class _ExpensesOverviewState extends ConsumerState<ExpensesOverview> {
  static const List<FavoriteFilterOption> _filterOptions = [
    FavoriteFilterOption(label: 'All', value: 'all'),
    FavoriteFilterOption(label: 'Unbilled', value: 'unbilled'),
    FavoriteFilterOption(label: 'Invoiced', value: 'invoiced'),
    FavoriteFilterOption(label: 'Reimbursed', value: 'reimbursed'),
    FavoriteFilterOption(label: 'Billable', value: 'billable'),
    FavoriteFilterOption(label: 'Non-Billable', value: 'non_billable'),
    FavoriteFilterOption(label: 'With Receipts', value: 'with_receipts'),
    FavoriteFilterOption(label: 'Without Receipts', value: 'without_receipts'),
  ];
  static const double _footerHeight = 76;
  static const double _recurringCompactFieldHeight = 32.0;
  static const List<String> _reportingTagLabels = <String>[
    'ADGF',
    'shedule',
    'demo adavced reporting tag',
  ];
  static const List<String> _reportingTagOptions = <String>[];

  OverlayEntry? _moreMenuOverlayEntry;
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  late FavoriteFilterOption _selectedFilter = _filterOptions.first;
  int _currentPage = 1;
  int _rowsPerPage = 100;
  bool _showTotalCount = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;
  bool _showPdfView = false;
  bool _showHistoryPanel = false;
  bool _showRecurringPanel = false;
  bool _isRecurringSubmitting = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  final GlobalKey _detailScrollViewKey = GlobalKey();
  final GlobalKey _journalSectionKey = GlobalKey();
  final TextEditingController _recurringProfileNameCtrl =
      TextEditingController();
  final TextEditingController _recurringStartOnCtrl = TextEditingController();
  final TextEditingController _recurringEndsOnCtrl = TextEditingController();
  final TextEditingController _recurringCustomRepeatIntervalCtrl =
      TextEditingController(text: '1');
  final GlobalKey _recurringStartOnFieldKey = GlobalKey();
  final GlobalKey _recurringEndsOnFieldKey = GlobalKey();
  String _recurringRepeatEvery = 'Week';
  String _recurringCustomRepeatUnit = 'Week(s)';
  String _recurringSourceOfSupply = '';
  DateTime _recurringStartOn = DateTime.now();
  DateTime? _recurringEndsOn;
  bool _recurringNeverExpires = true;
  late Map<String, String?> _selectedReportingTags = {
    for (final label in _reportingTagLabels) label: null,
  };

  @override
  void initState() {
    super.initState();
    _syncRecurringDateControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(expensesProvider.notifier).fetchExpenses(_buildListQuery());
    });
  }

  ExpensesListQuery _buildListQuery() {
    final state = ref.read(expensesProvider);
    return state.query.copyWith(
      page: _currentPage,
      limit: _rowsPerPage,
      favoriteFilter: _selectedFilter.value == 'all'
          ? null
          : _selectedFilter.value,
      sortBy: state.sortField,
      sortAscending: state.sortAscending,
    );
  }

  Future<void> _changePage(int nextPage) async {
    if (nextPage < 1) return;
    setState(() {
      _currentPage = nextPage;
    });
    await ref.read(expensesProvider.notifier).setPage(nextPage);
  }

  Future<void> _changePageSize(int nextPageSize) async {
    if (_rowsPerPage == nextPageSize) return;
    setState(() {
      _rowsPerPage = nextPageSize;
      _currentPage = 1;
    });
    await ref.read(expensesProvider.notifier).setPageSize(nextPageSize);
  }

  Future<void> _sortExpenses(String field, bool ascending) async {
    setState(() {
      _currentPage = 1;
    });
    await ref.read(expensesProvider.notifier).sort(field, ascending);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _detailScrollController.dispose();
    _recurringProfileNameCtrl.dispose();
    _recurringStartOnCtrl.dispose();
    _recurringEndsOnCtrl.dispose();
    _recurringCustomRepeatIntervalCtrl.dispose();
    _closeMoreMenu();
    super.dispose();
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final formatted = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\u20B9$formatted.$decPart';
  }

  String _displayExpenseAccount(ExpenseRecord record) {
    return displayExpenseAccountLabel(record);
  }

  Widget _buildExpenseAccountBadge(ExpenseRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _displayExpenseAccount(record),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w400,
              color: AppTheme.textBody,
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _tryParseExpenseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;

    final parts = value.split('-');
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;

    if (first > 31) {
      return DateTime.tryParse(
        '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
      );
    }

    return DateTime(third, second, first);
  }

  String _formatRecurringSidebarDate(
    DateTime? value, {
    String fallback = 'dd-MM-yyyy',
  }) {
    if (value == null) return fallback;
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  void _syncRecurringDateControllers() {
    _recurringStartOnCtrl.text = _formatRecurringSidebarDate(_recurringStartOn);
    _recurringEndsOnCtrl.text = _recurringEndsOn == null
        ? ''
        : _formatRecurringSidebarDate(_recurringEndsOn);
  }

  void _openRecurringPanel(ExpenseRecord record) {
    if (record.recurringExpenseId.trim().isNotEmpty) {
      ZerpaiToast.error(
        context,
        'This expense is already linked to a recurring profile.',
      );
      return;
    }
    final expenseDate = _tryParseExpenseDate(record.date);
    setState(() {
      _showHistoryPanel = false;
      _showRecurringPanel = true;
      _recurringProfileNameCtrl.clear();
      _recurringRepeatEvery = 'Week';
      _recurringCustomRepeatIntervalCtrl.text = '1';
      _recurringCustomRepeatUnit = 'Week(s)';
      _recurringSourceOfSupply =
          _normalizeStateName(record.sourceOfSupply) ?? record.sourceOfSupply;
      _recurringStartOn = expenseDate ?? DateTime.now();
      _recurringNeverExpires = true;
      _recurringEndsOn = null;
      _isRecurringSubmitting = false;
      _syncRecurringDateControllers();
    });
  }

  void _closeRecurringPanel() {
    setState(() => _showRecurringPanel = false);
  }

  String _formatRecurringApiDate(DateTime value) {
    return value.toIso8601String().split('T').first;
  }

  int _resolveRecurringRepeatEveryCount() {
    if (_recurringRepeatEvery == 'Custom') {
      return int.tryParse(_recurringCustomRepeatIntervalCtrl.text.trim()) ?? 1;
    }

    return switch (_recurringRepeatEvery) {
      '2 Weeks' => 2,
      '2 Months' => 2,
      '3 Months' => 3,
      '6 Months' => 6,
      '2 Years' => 2,
      '3 Years' => 3,
      _ => 1,
    };
  }

  RecurringRepeatType _resolveRecurringRepeatType() {
    if (_recurringRepeatEvery == 'Custom') {
      return switch (_recurringCustomRepeatUnit) {
        'Day(s)' => RecurringRepeatType.day,
        'Week(s)' => RecurringRepeatType.week,
        'Month(s)' => RecurringRepeatType.month,
        'Year(s)' => RecurringRepeatType.year,
        _ => RecurringRepeatType.week,
      };
    }

    return switch (_recurringRepeatEvery) {
      'Week' || '2 Weeks' => RecurringRepeatType.week,
      'Month' ||
      '2 Months' ||
      '3 Months' ||
      '6 Months' => RecurringRepeatType.month,
      'Year' || '2 Years' || '3 Years' => RecurringRepeatType.year,
      _ => RecurringRepeatType.week,
    };
  }

  CreateRecurringExpenseRequest _buildRecurringRequestFromExpense(
    ExpenseRecord record,
  ) {
    return CreateRecurringExpenseRequest(
      profileName: _recurringProfileNameCtrl.text.trim(),
      repeatEvery: _resolveRecurringRepeatEveryCount(),
      repeatType: _resolveRecurringRepeatType(),
      startDate: _formatRecurringApiDate(_recurringStartOn),
      endDate: _recurringNeverExpires || _recurringEndsOn == null
          ? null
          : _formatRecurringApiDate(_recurringEndsOn!),
      neverExpires: _recurringNeverExpires,
      status: RecurringExpenseStatus.active,
      expenseAccountId: record.expenseAccountId.isEmpty
          ? null
          : record.expenseAccountId,
      amount: record.amount,
      currencyCode: record.currencyCode.isEmpty ? 'INR' : record.currencyCode,
      paidThroughAccountId: record.paidThroughAccountId.isEmpty
          ? null
          : record.paidThroughAccountId,
      expenseType: record.expenseType.toUpperCase() == 'GOODS'
          ? ExpenseType.goods
          : ExpenseType.services,
      hsnSacCode: record.hsnSacCode.isEmpty ? null : record.hsnSacCode,
      vendorId: record.vendorId.isEmpty ? null : record.vendorId,
      gstTreatment: record.gstTreatment.isEmpty ? null : record.gstTreatment,
      sourceOfSupply: _recurringSourceOfSupply.trim().isEmpty
          ? (record.sourceOfSupply.isEmpty ? null : record.sourceOfSupply)
          : _recurringSourceOfSupply,
      destinationOfSupply: record.destinationOfSupply.isEmpty
          ? null
          : record.destinationOfSupply,
      reverseCharge: record.reverseCharge,
      taxId: record.taxId.isEmpty ? null : record.taxId,
      amountTaxMode: record.amountTaxMode.toUpperCase() == 'INCLUSIVE'
          ? AmountTaxMode.inclusive
          : AmountTaxMode.exclusive,
      invoiceNumber: record.invoiceNumber.isEmpty ? null : record.invoiceNumber,
      notes: record.notes,
      customerId: record.customerId.isEmpty ? null : record.customerId,
      includeCustomerIdField: record.customerId.isNotEmpty,
      isBillable: record.customerId.isNotEmpty && record.isBillable,
      autoCreate: true,
    );
  }

  UpsertExpenseRequest _buildRecurringLinkExpenseRequest(
    ExpenseRecord record,
    String recurringExpenseId,
  ) {
    return UpsertExpenseRequest(
      expenseNumber: record.expenseNumber.isEmpty ? null : record.expenseNumber,
      expenseDate: record.date,
      expenseMode: record.expenseMode,
      status: record.status.isEmpty ? null : record.status,
      isItemized: record.isItemized,
      expenseAccountId: record.expenseAccountId,
      paidThroughAccountId: record.paidThroughAccountId,
      amount: record.amount,
      currencyCode: record.currencyCode,
      expenseType: record.expenseType,
      hsnSacCode: record.hsnSacCode.isEmpty ? null : record.hsnSacCode,
      vendorId: record.vendorId.isEmpty ? null : record.vendorId,
      customerId: record.customerId.isEmpty ? null : record.customerId,
      gstTreatment: record.gstTreatment.isEmpty ? null : record.gstTreatment,
      sourceOfSupply: record.sourceOfSupply.isEmpty
          ? null
          : record.sourceOfSupply,
      destinationOfSupply: record.destinationOfSupply.isEmpty
          ? null
          : record.destinationOfSupply,
      reverseCharge: record.reverseCharge,
      taxId: record.taxId.isEmpty ? null : record.taxId,
      amountTaxMode: record.amountTaxMode,
      invoiceNumber: record.invoiceNumber.isEmpty ? null : record.invoiceNumber,
      notes: record.notes.isEmpty ? null : record.notes,
      isBillable: record.isBillable,
      subtotal: record.subtotal,
      taxAmount: record.taxAmount,
      totalAmount: record.totalAmount,
      recurringExpenseId: recurringExpenseId,
      items: record.items,
      mileage: record.mileage,
    );
  }

  Future<void> _saveRecurringFromExpense(ExpenseRecord record) async {
    if (_isRecurringSubmitting) {
      return;
    }
    if (record.recurringExpenseId.trim().isNotEmpty) {
      ZerpaiToast.error(
        context,
        'This expense is already linked to a recurring profile.',
      );
      return;
    }
    final profileName = _recurringProfileNameCtrl.text.trim();
    if (profileName.isEmpty) {
      ZerpaiToast.error(context, 'Profile Name is required');
      return;
    }
    if (_recurringRepeatEvery == 'Custom') {
      final interval =
          int.tryParse(_recurringCustomRepeatIntervalCtrl.text.trim()) ?? 0;
      if (interval <= 0) {
        ZerpaiToast.error(context, 'Repeat every must be greater than 0');
        return;
      }
    }
    setState(() {
      _isRecurringSubmitting = true;
    });

    try {
      final recurringRequest = _buildRecurringRequestFromExpense(record);
      final RecurringExpenseDetails recurring = await ref.read(
        createRecurringExpenseProvider(recurringRequest).future,
      );

      await ref
          .read(expensesRepositoryProvider)
          .updateExpense(
            UpdateExpenseRequest(
              id: record.id,
              expense: _buildRecurringLinkExpenseRequest(record, recurring.id),
            ),
          );

      ref.invalidate(recurringExpensesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(expenseDetailsProvider(record.id));
      ref.invalidate(expenseHistoryProvider(record.id));
      ref.invalidate(expenseJournalProvider(record.id));

      if (!mounted) {
        return;
      }

      ZerpaiToast.success(context, 'Recurring expense created successfully.');
      _closeRecurringPanel();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ZerpaiToast.error(context, error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRecurringSubmitting = false;
        });
      }
    }
  }

  Future<void> _showReportingTagsDialog() async {
    final updated = await showDialog<Map<String, String?>>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return _AssociateTagsDialog(
          initialValues: _selectedReportingTags,
          labels: _reportingTagLabels,
          options: _reportingTagOptions,
        );
      },
    );

    if (updated != null && mounted) {
      setState(() {
        _selectedReportingTags = Map<String, String?>.from(updated);
      });
    }
  }

  Future<void> _pickRecurringDate({
    required GlobalKey targetKey,
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: targetKey,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _scrollToJournalSection() async {
    final journalContext = _journalSectionKey.currentContext;
    final detailScrollContext = _detailScrollViewKey.currentContext;
    if (journalContext == null || detailScrollContext == null) {
      return;
    }

    final journalBox = journalContext.findRenderObject() as RenderBox?;
    final scrollBox = detailScrollContext.findRenderObject() as RenderBox?;
    if (journalBox == null || scrollBox == null) {
      return;
    }

    final topOffset = journalBox
        .localToGlobal(Offset.zero, ancestor: scrollBox)
        .dy;
    final bottomOffset = topOffset + journalBox.size.height;
    final isVisible = topOffset >= 0 && bottomOffset <= scrollBox.size.height;
    if (isVisible) {
      return;
    }

    await Scrollable.ensureVisible(
      journalContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMoreMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _moreMenuLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topLeft,
              targetAnchor: Alignment.bottomLeft,
              offset: const Offset(-182, 8),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _MoreMenuDropdownContent(
                  onClose: _closeMoreMenu,
                  activeSubMenu: _activeSubMenu,
                  onSubMenuChanged: (type) {
                    if (_activeSubMenu == type) return;
                    _activeSubMenu = type;
                    _moreMenuOverlayEntry?.markNeedsBuild();
                  },
                  sortField: ref.watch(expensesProvider).sortField,
                  sortAscending: ref.watch(expensesProvider).sortAscending,
                  onSort: (field, asc) {
                    unawaited(_sortExpenses(field, asc));
                  },
                  onRefresh: () async {
                    await ref
                        .read(expensesProvider.notifier)
                        .fetchExpenses(_buildListQuery());
                  },
                  onImport: _pickUploadExpenseFile,
                  onExportExpenses: _showExportExpensesDialog,
                  onExportCurrentView: _openExportCurrentViewDialog,
                  onResetWidths: () {
                    _closeMoreMenu();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_moreMenuOverlayEntry!);
    setState(() {
      _isMoreMenuOpen = true;
    });
  }

  void _showExportExpensesDialog() {
    showExpensesExportDialog(context, rows: ref.read(expensesProvider).records);
  }

  void _openExportCurrentViewDialog() {
    final state = ref.read(expensesProvider);
    showExpensesExportCurrentViewDialog(
      context,
      rows: state.records,
      columns: [
        ExpensesCurrentViewExportColumn(
          label: 'Expense Account',
          valueBuilder: _displayExpenseAccount,
        ),
        ExpensesCurrentViewExportColumn(
          label: 'Date',
          valueBuilder: (row) => row.date,
        ),
        ExpensesCurrentViewExportColumn(
          label: 'Amount',
          valueBuilder: (row) => _fmt(row.amount),
        ),
      ],
    );
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    setState(() {
      _isMoreMenuOpen = false;
      _activeSubMenu = _SubMenuType.none;
    });
  }

  Future<void> _pickUploadExpenseFile() async {
    if (widget.expenseId.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please open an expense before uploading.');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final files = result.files.where((file) => file.bytes != null).toList();
      if (files.isEmpty) {
        if (mounted) {
          ZerpaiToast.error(
            context,
            'Selected files are not available for upload.',
          );
        }
        return;
      }

      await ref
          .read(expensesRepositoryProvider)
          .uploadReceiptFiles(expenseId: widget.expenseId, files: files);

      ref.invalidate(expenseDetailsProvider(widget.expenseId));
      ref.invalidate(expenseAttachmentsProvider(widget.expenseId));
      await ref.read(expensesProvider.notifier).refresh();
      if (!mounted) return;
      ZerpaiToast.success(
        context,
        files.length == 1
            ? 'Attachment uploaded successfully.'
            : '${files.length} attachments uploaded successfully.',
      );
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to upload attachment: $e');
      }
    }
  }

  Future<void> _deleteAttachment(ExpenseAttachmentModel attachment) async {
    try {
      final deleted = await ref
          .read(expensesRepositoryProvider)
          .deleteAttachment(
            expenseId: widget.expenseId,
            attachmentId: attachment.id,
          );
      if (!mounted) return;
      if (!deleted) {
        ZerpaiToast.error(context, 'Failed to delete attachment.');
        return;
      }
      ref.invalidate(expenseDetailsProvider(widget.expenseId));
      ref.invalidate(expenseAttachmentsProvider(widget.expenseId));
      await ref.read(expensesProvider.notifier).refresh();
      if (!mounted) return;
      ZerpaiToast.success(context, 'Attachment deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to delete attachment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesProvider);
    final notifier = ref.read(expensesProvider.notifier);
    final detailAsync = widget.expenseId.isEmpty
        ? const AsyncValue<ExpenseRecord?>.data(null)
        : ref.watch(expenseDetailsProvider(widget.expenseId));

    final filteredRecords = state.records;
    final paginatedRecords = filteredRecords;
    final bool showPaginationFooter = state.totalRecords > 10;

    final selectedCount = state.records.where((r) => r.isSelected).length;

    bool allSelected = paginatedRecords.isNotEmpty;
    for (final r in paginatedRecords) {
      if (!r.isSelected) {
        allSelected = false;
        break;
      }
    }

    final listRecord = state.records.firstWhere(
      (r) => r.id == widget.expenseId,
      orElse: () => state.records.isNotEmpty
          ? state.records.first
          : ExpenseRecord.empty(),
    );
    final selectedRecord = detailAsync.valueOrNull ?? listRecord;

    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    if (state.isLoading && state.records.isEmpty) {
      return _buildInitialLoadingPage();
    }

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: SplitListDetailLayout(
          leftWidth: 380,
          leftHeader: selectedCount > 0
              ? _buildLeftBulkActionHeader(
                  selectedCount,
                  allSelected,
                  0,
                  paginatedRecords.length,
                  ref,
                  context,
                )
              : _buildLeftHeader(orgSystemId),
          leftBody: state.isLoading
              ? _buildOverviewListLoading()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: paginatedRecords.length,
                        itemBuilder: (context, index) {
                          final r = paginatedRecords[index];
                          final isSelected = r.id == widget.expenseId;
                          final absoluteIndex = state.records.indexOf(r);
                          return _ExpenseListCard(
                            record: r,
                            isSelected: isSelected,
                            onTap: () {
                              context.go(
                                '/$orgSystemId/purchases/expenses/${r.id}',
                              );
                            },
                            onChanged: (val) {
                              notifier.toggleRecordSelect(absoluteIndex, val);
                            },
                          );
                        },
                      ),
                    ),
                    if (showPaginationFooter)
                      _buildLeftFooter(state.totalRecords),
                  ],
                ),
          rightHeader: null,
          rightBody: detailAsync.when(
            data: (record) => _buildRightPane(record ?? selectedRecord),
            loading: _buildOverviewDetailLoading,
            error: (error, _) => Center(
              child: Text(
                error.toString(),
                style: AppTextStyles.body.copyWith(color: AppTheme.errorRed),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewListLoading() {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(AppTheme.space16),
      child: const ZListSkeleton(itemCount: 6),
    );
  }

  Widget _buildInitialLoadingPage() {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: const SplitListDetailLayout(
          leftWidth: 380,
          leftHeader: SizedBox(height: 56), // Placeholder
          leftBody: ZListSkeleton(itemCount: 8),
          rightHeader: null,
          rightBody: SingleChildScrollView(child: ZDetailContentSkeleton()),
        ),
      ),
    );
  }

  Widget _buildOverviewDetailLoading() {
    return const SingleChildScrollView(child: ZDetailContentSkeleton());
  }

  Widget _buildLeftHeader(String orgSystemId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ExpensesFilterDropdownWidget(
              moduleName: 'expenses',
              options: _filterOptions,
              selectedOption: _selectedFilter,
              onChanged: (option) {
                setState(() {
                  _selectedFilter = option;
                  _currentPage = 1;
                });
                ref.read(expensesProvider.notifier).updateFilter(option.value);
              },
            ),
          ),
          const SizedBox(width: 12),
          _FilledActionSquare(
            icon: LucideIcons.plus,
            onTap: () => context.go('/$orgSystemId/purchases/expenses/create'),
          ),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _moreMenuLayerLink,
            child: _OutlineActionSquare(
              icon: LucideIcons.moreHorizontal,
              color: _isMoreMenuOpen
                  ? AppTheme.primaryBlueDark
                  : AppTheme.textSecondary,
              onTap: () {
                if (_isMoreMenuOpen) {
                  _closeMoreMenu();
                } else {
                  _showMoreMenu();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftBulkActionHeader(
    int selectedCount,
    bool allSelected,
    int startIndex,
    int endIndex,
    WidgetRef ref,
    BuildContext context,
  ) {
    final state = ref.watch(expensesProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: const BoxDecoration(
        color: AppTheme.bgDisabled,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Checkbox(
                      value: allSelected,
                      onChanged: (val) {
                        ref
                            .read(expensesProvider.notifier)
                            .toggleSelectAll(
                              val ?? false,
                              startIndex,
                              endIndex,
                            );
                      },
                      activeColor: AppTheme.primaryBlue,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Bulk Actions',
                    padding: EdgeInsets.zero,
                    offset: const Offset(0, 32),
                    color: AppTheme.backgroundColor,
                    surfaceTintColor: AppTheme.backgroundColor,
                    elevation: 8,
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    constraints: const BoxConstraints.tightFor(width: 206),
                    onSelected: (action) {
                      if (action == 'update') {
                        showDialog(
                          context: context,
                          builder: (context) => ExpensesBulkUpdateDialog(
                            fields: const [
                              'Expense Account',
                              'Paid Through',
                              'Date',
                              'Billable',
                              'Reference#',
                              'Notes',
                              'Customer Name',
                            ],
                            onUpdate: (field, value) {
                              ref
                                  .read(expensesProvider.notifier)
                                  .bulkUpdate(field, value);
                              ref
                                  .read(expensesProvider.notifier)
                                  .toggleSelectAll(
                                    false,
                                    0,
                                    state.records.length,
                                  );
                              ZerpaiToast.success(
                                context,
                                'Expenses updated successfully',
                              );
                            },
                          ),
                        );
                      } else if (action == 'delete') {
                        showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Expenses',
                          message:
                              'Are you sure about deleting the selected expense(s)?',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          variant: ZerpaiConfirmationVariant.danger,
                        ).then((confirmed) {
                          if (confirmed == true) {
                            unawaited(
                              ref
                                  .read(expensesProvider.notifier)
                                  .deleteSelected(),
                            );
                            ref
                                .read(expensesProvider.notifier)
                                .toggleSelectAll(
                                  false,
                                  0,
                                  state.records.length,
                                );
                            ZerpaiToast.deleted(context, 'Expense(s)');
                          }
                        });
                      } else if (action == 'pdf') {
                        ZerpaiToast.success(context, 'Exporting PDF...');
                      } else if (action == 'print') {
                        ZerpaiToast.success(context, 'Preparing print...');
                      } else if (action == 'download') {
                        ref
                            .read(expensesProvider.notifier)
                            .toggleSelectAll(false, 0, state.records.length);
                        ZerpaiToast.success(
                          context,
                          'Downloading receipt(s)...',
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'update',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(label: 'Bulk Update'),
                      ),
                      PopupMenuItem<String>(
                        value: 'pdf',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(label: 'Export as PDF'),
                      ),
                      PopupMenuItem<String>(
                        value: 'print',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(label: 'Print'),
                      ),
                      PopupMenuItem<String>(
                        value: 'download',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(label: 'Download Receipt'),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'delete',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(label: 'Delete'),
                      ),
                    ],
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bulk Actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: AppTheme.borderColor,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.infoBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$selectedCount',
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Selected',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ref
                    .read(expensesProvider.notifier)
                    .toggleSelectAll(false, 0, state.records.length);
              },
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, right: 2),
                child: Icon(LucideIcons.x, color: AppTheme.errorRed, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightHeader(ExpenseRecord r) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final hasRecurringLink = r.recurringExpenseId.trim().isNotEmpty;
    final isMileageExpense = isMileageExpenseRecord(r);
    final subtitle = r.paidThrough.isNotEmpty
        ? 'Paid Through: ${r.paidThrough}'
        : (r.vendorName.isNotEmpty ? 'Vendor: ${r.vendorName}' : null);

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: AppTheme.metaHelper.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'Expense Details',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ZTooltip(
                              message: 'Expense History',
                              direction: ZTooltipDirection.bottom,
                              child: _OutlineActionSquare(
                                icon: LucideIcons.messageSquare,
                                color: AppTheme.textSecondary,
                                onTap: () {
                                  setState(() {
                                    _showRecurringPanel = false;
                                    _showHistoryPanel = !_showHistoryPanel;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppTheme.borderColor,
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                context.go('/$orgSystemId/purchases/expenses');
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 18,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.bgDisabled,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolbarButton(
                    icon: LucideIcons.pencil,
                    label: 'Edit',
                    onTap: () {
                      final currentUri = GoRouterState.of(
                        context,
                      ).uri.toString();
                      context.go(
                        '/$orgSystemId/purchases/expenses/create?mode=edit&id=${Uri.encodeComponent(r.id)}&returnTo=${Uri.encodeComponent(currentUri)}',
                      );
                    },
                  ),
                  if (!hasRecurringLink && !isMileageExpense) ...[
                    _buildToolbarDivider(),
                    _buildToolbarButton(
                      icon: LucideIcons.refreshCcw,
                      label: 'Make Recurring',
                      onTap: () {
                        _openRecurringPanel(r);
                      },
                    ),
                  ],
                  _buildToolbarDivider(),
                  _buildPdfPrintDropdown(r),
                  _buildToolbarDivider(),
                  PopupMenuButton<String>(
                    tooltip: 'More Options',
                    color: AppTheme.backgroundColor,
                    surfaceTintColor: AppTheme.backgroundColor,
                    elevation: 8,
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    constraints: const BoxConstraints.tightFor(width: 168),
                    onSelected: (val) {
                      if (val == 'clone') {
                        final currentUri = GoRouterState.of(
                          context,
                        ).uri.toString();
                        context.go(
                          '/$orgSystemId/purchases/expenses/create?mode=clone&id=${Uri.encodeComponent(r.id)}&returnTo=${Uri.encodeComponent(currentUri)}',
                        );
                      } else if (val == 'delete') {
                        showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Expense',
                          message:
                              'Are you sure you want to delete this expense?',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          variant: ZerpaiConfirmationVariant.danger,
                        ).then((confirmed) {
                          if (confirmed == true) {
                            ref
                                .read(expensesProvider.notifier)
                                .deleteExpenseById(r.id);
                            ZerpaiToast.deleted(context, 'Expense');
                            context.go('/$orgSystemId/purchases/expenses');
                          }
                        });
                      } else if (val == 'journal') {
                        _scrollToJournalSection();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'clone',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(
                          label: 'Clone',
                          icon: LucideIcons.copy,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(
                          label: 'Delete',
                          icon: LucideIcons.trash2,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'journal',
                        padding: EdgeInsets.zero,
                        height: 40,
                        child: _HoverPopupMenuItem(
                          label: 'View Journal',
                          icon: LucideIcons.bookCopy,
                        ),
                      ),
                    ],
                    child: const _HoverMoreButtonChild(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    IconData? trailingIcon,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarButton(
      icon: icon,
      label: label,
      trailingIcon: trailingIcon,
      onTap: onTap,
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 16,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPdfPrintDropdown(ExpenseRecord expense) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final menuItemStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? AppTheme.primaryBlue
            : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? Colors.white
            : AppTheme.textPrimary,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? Colors.white
            : AppTheme.primaryBlue,
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(190, 44)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(8),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateExpensePdf(expense, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: _expensePdfFileName(expense),
            );
          },
          style: menuItemStyle,
          child: const Row(
            children: [
              Icon(LucideIcons.fileText, size: 16),
              SizedBox(width: 12),
              Text('PDF', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateExpensePdf(expense, orgSettings);
            if (!mounted) return;
            await showDialog<void>(
              context: context,
              useRootNavigator: false,
              builder: (dialogContext) => ExpenseGeneratedPdfPreviewDialog(
                title: _expensePdfFileName(expense),
                pdfBytes: bytes,
                onPrint: () async {
                  await Printing.layoutPdf(
                    onLayout: (_) async => bytes,
                    name: expense.expenseNumber.isNotEmpty
                        ? expense.expenseNumber
                        : 'expense',
                  );
                },
              ),
            );
          },
          style: menuItemStyle,
          child: const Row(
            children: [
              Icon(LucideIcons.printer, size: 16),
              SizedBox(width: 12),
              Text('Print', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        if (!_showPdfView)
          MenuItemButton(
            onPressed: () async {
              await _printNonPdfExpenseView(expense);
            },
            style: menuItemStyle,
            child: const Row(
              children: [
                Icon(LucideIcons.printer, size: 16),
                SizedBox(width: 12),
                Text('Print Non-PDF View', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
      ],
      builder: (context, controller, _) => _buildToolbarButton(
        icon: LucideIcons.fileText,
        label: 'PDF/Print',
        trailingIcon: LucideIcons.chevronDown,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  String _expensePdfFileName(ExpenseRecord expense) {
    final number = expense.expenseNumber.trim();
    if (number.isNotEmpty) {
      return '$number.pdf';
    }
    final reference = expense.reference.trim();
    if (reference.isNotEmpty) {
      return '$reference.pdf';
    }
    return 'expense.pdf';
  }

  Future<void> _printNonPdfExpenseView(ExpenseRecord expense) async {
    final iframe = import_web.HTMLIFrameElement()
      ..style.position = 'fixed'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.width = '0'
      ..style.height = '0'
      ..style.border = '0'
      ..style.visibility = 'hidden'
      ..style.pointerEvents = 'none'
      ..srcdoc = _buildNonPdfPrintDocument(expense).toJS;

    final body = import_web.document.body;
    if (body == null) {
      return;
    }

    body.append(iframe);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      iframe.contentWindow?.focus();
      iframe.contentWindow?.print();
    } finally {
      Future<void>.delayed(const Duration(seconds: 2), () {
        iframe.remove();
      });
    }
  }

  String _buildNonPdfPrintDocument(ExpenseRecord expense) {
    final amountText = _fmt(expense.amount);
    final displayDate = expense.date.trim().isEmpty ? '-' : expense.date.trim();
    final accountName = _escapePrintHtml(expense.expenseAccount);
    final status = _escapePrintHtml(expense.status);
    final paidThrough = _escapePrintHtml(expense.paidThrough);
    final reference = _escapePrintHtml(expense.reference);
    final gstTreatment = _escapePrintHtml(expense.gstTreatment);
    final sourceOfSupply = _escapePrintHtml(
      _displayStateName(expense.sourceOfSupply),
    );
    final destinationOfSupply = _escapePrintHtml(
      _displayStateName(expense.destinationOfSupply),
    );
    final reverseCharge = expense.reverseCharge ? 'Yes' : '';
    final vendorName = _escapePrintHtml(expense.vendorName);
    final customerName = _escapePrintHtml(expense.customerName);
    final notes = _escapePrintHtml(expense.notes);
    final attachmentCard = _buildNonPdfPrintAttachmentCard(expense.attachments);
    final detailRows = <String>[
      _buildPrintDetailBlock('Paid Through', paidThrough),
      _buildPrintDetailBlock('Ref #', reference),
      _buildPrintDetailBlock('GST Treatment', gstTreatment),
      _buildPrintDetailBlock('Source of Supply', sourceOfSupply),
      if (destinationOfSupply.trim().isNotEmpty)
        _buildPrintDetailBlock('Destination of Supply', destinationOfSupply),
      if (reverseCharge.trim().isNotEmpty)
        _buildPrintDetailBlock('Reverse Charge', reverseCharge),
      if (vendorName.trim().isNotEmpty)
        _buildPrintDetailBlock('Vendor Name', vendorName),
      if (customerName.trim().isNotEmpty)
        _buildPrintDetailBlock('Customer Name', customerName),
      if (notes.trim().isNotEmpty) _buildPrintDetailBlock('Notes', notes),
    ];

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Expense Details</title>
    <style>
      * { box-sizing: border-box; }
      html, body {
        margin: 0;
        padding: 0;
        background: #ffffff;
        color: #111827;
        font-family: Arial, Helvetica, sans-serif;
      }
      body { padding: 24px 30px 40px; }
      .page {
        width: 100%;
        max-width: 820px;
        margin: 0 auto;
      }
      .heading {
        font-size: 28px;
        font-weight: 600;
        margin: 0 0 18px;
        padding-bottom: 12px;
        border-bottom: 1px solid #e5e7eb;
      }
      .content {
        display: flex;
        align-items: flex-start;
        gap: 48px;
      }
      .left {
        flex: 1 1 auto;
        min-width: 0;
      }
      .right {
        width: 246px;
        flex: 0 0 246px;
      }
      .amount-label {
        font-size: 14px;
        color: #6b7280;
        margin-bottom: 4px;
      }
      .amount-row {
        display: flex;
        align-items: baseline;
        gap: 6px;
        flex-wrap: wrap;
      }
      .amount-value {
        font-size: 30px;
        font-weight: 700;
        color: #ef4444;
      }
      .amount-date {
        font-size: 13px;
        color: #6b7280;
      }
      .status {
        margin-top: 6px;
        font-size: 14px;
        font-weight: 500;
        color: #111827;
      }
      .account-chip {
        display: inline-block;
        margin-top: 20px;
        padding: 6px 14px;
        background: #e9f1fb;
        border-radius: 2px;
        color: #374151;
        font-size: 13px;
      }
      .account-title {
        margin: 34px 0 28px;
        font-size: 20px;
        font-weight: 500;
        color: #111827;
      }
      .field {
        margin-bottom: 24px;
      }
      .field-label {
        font-size: 13px;
        color: #6b7280;
        margin-bottom: 6px;
      }
      .field-value {
        font-size: 14px;
        color: #111827;
        line-height: 1.4;
        white-space: pre-wrap;
        word-break: break-word;
      }
      .attachment-card {
        width: 246px;
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        overflow: hidden;
        background: #ffffff;
      }
      .attachment-header {
        height: 42px;
        border-bottom: 1px solid #e5e7eb;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        font-size: 13px;
        font-weight: 500;
        color: #374151;
      }
      .attachment-body {
        height: 244px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 18px;
      }
      .attachment-footer {
        height: 44px;
        border-top: 1px dashed #d1d5db;
        display: flex;
        align-items: center;
        padding: 0 12px;
        font-size: 13px;
        color: #6b7280;
      }
      .preview-wrap {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
        width: 100%;
        height: 100%;
      }
      .pdf-icon {
        width: 100px;
        height: 100px;
        border: 5px solid #d32f2f;
        border-radius: 18px;
        color: #d32f2f;
        font-size: 36px;
        font-weight: 700;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 14px;
      }
      .file-name {
        max-width: 170px;
        font-size: 13px;
        color: #6b7280;
        line-height: 1.35;
        word-break: break-word;
      }
      .image-preview {
        max-width: 164px;
        max-height: 164px;
        border-radius: 6px;
        object-fit: contain;
        margin-bottom: 16px;
      }
      .footer {
        position: fixed;
        left: 0;
        right: 0;
        bottom: 10px;
        text-align: right;
        padding: 0 22px;
        font-size: 11px;
        color: #6b7280;
      }
      @media print {
        body { padding: 18px 24px 34px; }
        .page { max-width: none; }
      }
    </style>
  </head>
  <body>
    <div class="page">
      <h1 class="heading">Expense Details</h1>
      <div class="content">
        <div class="left">
          <div class="amount-label">Expense Amount</div>
          <div class="amount-row">
            <div class="amount-value">${_escapePrintHtml(amountText)}</div>
            <div class="amount-date">on ${_escapePrintHtml(displayDate)}</div>
          </div>
          <div class="status">$status</div>
          <div class="account-chip">$accountName</div>
          <div class="account-title">$accountName</div>
          ${detailRows.join()}
        </div>
        <div class="right">
          $attachmentCard
        </div>
      </div>
    </div>
    <div class="footer">1 / 1</div>
  </body>
</html>
''';
  }

  String _buildPrintDetailBlock(String label, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return '';
    }
    return '''
<div class="field">
  <div class="field-label">${_escapePrintHtml(label)}</div>
  <div class="field-value">$trimmed</div>
</div>
''';
  }

  String _buildNonPdfPrintAttachmentCard(
    List<ExpenseAttachmentModel> attachments,
  ) {
    final attachment = attachments.isNotEmpty ? attachments.first : null;
    final countLabel = attachments.isEmpty
        ? '0 of 0 Files'
        : '1 of ${attachments.length} Files';
    final preview = attachment == null
        ? '<div class="preview-wrap"></div>'
        : _isImageAttachmentForPrint(attachment)
        ? '''
<div class="preview-wrap">
  <img class="image-preview" src="${_escapePrintHtml(attachment.fileUrl)}" alt="${_escapePrintHtml(_attachmentDisplayNameForPrint(attachment))}">
  <div class="file-name">${_escapePrintHtml(_attachmentDisplayNameForPrint(attachment))}</div>
</div>
'''
        : '''
<div class="preview-wrap">
  <div class="pdf-icon">PDF</div>
  <div class="file-name">${_escapePrintHtml(_attachmentDisplayNameForPrint(attachment))}</div>
</div>
''';

    return '''
<div class="attachment-card">
  <div class="attachment-header">Upload your Files</div>
  <div class="attachment-body">
    $preview
  </div>
  <div class="attachment-footer">$countLabel</div>
</div>
''';
  }

  bool _isImageAttachmentForPrint(ExpenseAttachmentModel attachment) {
    final fileType = (attachment.fileType ?? '').trim().toLowerCase();
    if (fileType.startsWith('image/')) {
      return true;
    }
    final fileName = _attachmentDisplayNameForPrint(attachment).toLowerCase();
    return fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.gif') ||
        fileName.endsWith('.webp');
  }

  String _attachmentDisplayNameForPrint(ExpenseAttachmentModel attachment) {
    final original = (attachment.originalFileName ?? '').trim();
    if (original.isNotEmpty) {
      return original;
    }
    final stored = attachment.fileName.trim();
    if (stored.isNotEmpty) {
      return stored;
    }
    return 'Attachment';
  }

  String _escapePrintHtml(String value) {
    return json.HtmlEscape().convert(value);
  }

  Future<Uint8List> _generateExpensePdf(
    ExpenseRecord expense,
    OrgSettings? orgSettings,
  ) async {
    final doc = pw.Document();
    pw.ThemeData theme;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Inter-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      final regularFont = pw.Font.ttf(regularData);
      final boldFont = pw.Font.ttf(boldData);
      theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    } catch (_) {
      theme = pw.ThemeData.withFont();
    }

    pw.MemoryImage? logoImage;
    final logoUrl = orgSettings?.logoUrl?.trim();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final res = await Dio().get<List<int>>(
          logoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data!));
        }
      } catch (_) {}
    }

    final infoRows = <MapEntry<String, String>>[
      MapEntry('Expense Date', expense.date),
      MapEntry('Reference#', expense.reference),
      MapEntry('Expense Account', expense.expenseAccount),
      MapEntry('Currency Code', expense.currencyCode),
      MapEntry('Paid Through', expense.paidThrough),
      if (expense.gstTreatment.trim().isNotEmpty)
        MapEntry('GST Treatment', expense.gstTreatment),
      if (expense.sourceOfSupply.trim().isNotEmpty)
        MapEntry('Source of Supply', expense.sourceOfSupply),
      if (expense.destinationOfSupply.trim().isNotEmpty)
        MapEntry('Destination of Supply', expense.destinationOfSupply),
      MapEntry(
        'Notes',
        expense.notes.trim().isNotEmpty
            ? expense.notes.trim()
            : expense.reference,
      ),
    ];

    final addressLines = _buildPdfAddressLines(orgSettings)
        .map((widget) => widget is Text ? widget.data ?? '' : '')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (pw.Context pdfContext) {
          return pw.Stack(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (logoImage != null)
                                pw.Container(
                                  width: 140,
                                  height: 62,
                                  padding: const pw.EdgeInsets.all(6),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.grey300,
                                    ),
                                  ),
                                  child: pw.Image(
                                    logoImage,
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),
                              if (logoImage != null) pw.SizedBox(height: 18),
                              pw.Text(
                                orgSettings?.name.trim().isNotEmpty == true
                                    ? orgSettings!.name.trim()
                                    : 'ZABNIX PRIVATE LIMITED',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              ...addressLines.map(
                                (line) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 2),
                                  child: pw.Text(
                                    line,
                                    style: const pw.TextStyle(
                                      fontSize: 11,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(height: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 28),
                    pw.Text(
                      'EXPENSE',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 34),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: infoRows
                                .map((entry) {
                                  return pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        bottom: pw.BorderSide(
                                          color: PdfColors.grey300,
                                        ),
                                      ),
                                    ),
                                    child: pw.Row(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.SizedBox(
                                          width: 120,
                                          child: pw.Text(
                                            entry.key,
                                            style: const pw.TextStyle(
                                              fontSize: 11,
                                              color: PdfColors.grey800,
                                            ),
                                          ),
                                        ),
                                        pw.Expanded(
                                          child: pw.Text(
                                            entry.value.trim().isEmpty
                                                ? '-'
                                                : entry.value,
                                            style: pw.TextStyle(
                                              fontSize: 11,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                        pw.SizedBox(width: 24),
                        pw.Container(
                          width: 156,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          color: PdfColor.fromHex('#79B65A'),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'Expense Amount',
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 11,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                _fmt(expense.amount),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Widget _buildRightBody(ExpenseRecord r) {
    if (r.id.isEmpty) {
      return const Center(child: Text('No expense selected.'));
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: _detailScrollViewKey,
              controller: _detailScrollController,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'Show PDF View',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Transform.scale(
                        scale: 0.72,
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: _showPdfView,
                          onChanged: (value) {
                            setState(() => _showPdfView = value);
                          },
                          activeTrackColor: AppTheme.primaryBlue,
                          inactiveTrackColor: AppTheme.borderMid,
                          activeThumbColor: AppTheme.backgroundColor,
                          inactiveThumbColor: AppTheme.backgroundColor,
                          trackOutlineColor: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _showPdfView
                        ? _buildA4ExpensePreview(r)
                        : _buildStandardOverviewContent(r),
                  ),
                  if (_showPdfView) ...[
                    const SizedBox(height: 30),
                    _buildJournalSection(r),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane(ExpenseRecord r) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              _buildRightHeader(r),
              Expanded(child: _buildRightBody(r)),
            ],
          ),
        ),
        if (_showHistoryPanel)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _buildExpenseHistoryPanel(r),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          top: 0,
          right: _showRecurringPanel ? 0 : -496,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !_showRecurringPanel,
            child: _buildMakeRecurringPanel(r),
          ),
        ),
      ],
    );
  }

  Widget _buildMakeRecurringPanel(ExpenseRecord r) {
    return SizedBox(
      width: 462,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 14, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Make Recurring',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _closeRecurringPanel,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: Icon(
                        LucideIcons.x,
                        size: 17,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecurringSidebarRow(
                      label: 'Profile Name',
                      required: true,
                      child: CustomTextField(
                        controller: _recurringProfileNameCtrl,
                        height: _recurringCompactFieldHeight,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildRecurringSidebarRow(
                      label: 'Repeat Every',
                      required: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormDropdown<String>(
                            value: _recurringRepeatEvery,
                            items: const [
                              'Week',
                              '2 Weeks',
                              'Month',
                              '2 Months',
                              '3 Months',
                              '6 Months',
                              'Year',
                              '2 Years',
                              '3 Years',
                              'Custom',
                            ],
                            hint: 'Select repeat',
                            showSearch: false,
                            height: _recurringCompactFieldHeight,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _recurringRepeatEvery = value;
                                if (value != 'Custom') {
                                  _recurringCustomRepeatIntervalCtrl.text = '1';
                                  _recurringCustomRepeatUnit = 'Week(s)';
                                }
                              });
                            },
                          ),
                          if (_recurringRepeatEvery == 'Custom') ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: CustomTextField(
                                    controller:
                                        _recurringCustomRepeatIntervalCtrl,
                                    height: _recurringCompactFieldHeight,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: FormDropdown<String>(
                                    value: _recurringCustomRepeatUnit,
                                    items: const [
                                      'Day(s)',
                                      'Week(s)',
                                      'Month(s)',
                                      'Year(s)',
                                    ],
                                    showSearch: false,
                                    height: _recurringCompactFieldHeight,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(
                                        () =>
                                            _recurringCustomRepeatUnit = value,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildRecurringSidebarRow(
                      label: 'Start On',
                      child: Container(
                        key: _recurringStartOnFieldKey,
                        child: CustomTextField(
                          controller: _recurringStartOnCtrl,
                          height: _recurringCompactFieldHeight,
                          readOnly: true,
                          onTap: () {
                            _pickRecurringDate(
                              targetKey: _recurringStartOnFieldKey,
                              initialDate: _recurringStartOn,
                              onSelected: (date) {
                                setState(() {
                                  _recurringStartOn = date;
                                  _syncRecurringDateControllers();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildRecurringSidebarRow(
                      label: 'Ends On',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            key: _recurringEndsOnFieldKey,
                            child: CustomTextField(
                              controller: _recurringEndsOnCtrl,
                              hintText: 'dd-MM-yyyy',
                              height: _recurringCompactFieldHeight,
                              readOnly: true,
                              enabled: !_recurringNeverExpires,
                              onTap: _recurringNeverExpires
                                  ? null
                                  : () {
                                      _pickRecurringDate(
                                        targetKey: _recurringEndsOnFieldKey,
                                        initialDate:
                                            _recurringEndsOn ??
                                            _recurringStartOn.add(
                                              const Duration(days: 7),
                                            ),
                                        onSelected: (date) {
                                          setState(() {
                                            _recurringEndsOn = date;
                                            _syncRecurringDateControllers();
                                          });
                                        },
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _recurringNeverExpires,
                                activeColor: AppTheme.primaryBlueDark,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (value) {
                                  setState(() {
                                    _recurringNeverExpires = value ?? true;
                                    if (_recurringNeverExpires) {
                                      _recurringEndsOn = null;
                                    }
                                    _syncRecurringDateControllers();
                                  });
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Never Expires',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildRecurringSidebarRow(
                      label: 'Reporting Tags',
                      labelTopPadding: 7,
                      child: SizedBox(
                        height: _recurringCompactFieldHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.tag,
                                size: 14,
                                color: AppTheme.primaryBlueDark,
                              ),
                              const SizedBox(width: 6),
                              _SidebarActionText(
                                text: 'Associate Tags',
                                onTap: _showReportingTagsDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
                color: AppTheme.backgroundColor,
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: _isRecurringSubmitting
                        ? null
                        : () => _saveRecurringFromExpense(r),
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: _closeRecurringPanel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSidebarRow({
    required String label,
    required Widget child,
    bool required = false,
    double labelTopPadding = 10,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Padding(
            padding: EdgeInsets.only(top: labelTopPadding),
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyText.copyWith(
                  fontSize: 14,
                  color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                ),
                children: [
                  TextSpan(text: label),
                  if (required)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildExpenseHistoryPanel(ExpenseRecord r) {
    final entriesAsync = ref.watch(expenseHistoryProvider(r.id));
    return SizedBox(
      width: 408,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 14, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Expense History',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _showHistoryPanel = false);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: Icon(
                        LucideIcons.x,
                        size: 17,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return _buildExpenseHistoryEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 24, 18, 28),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 30),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isLast = index == entries.length - 1;
                      return _buildHistoryTimelineEntry(
                        _ExpenseHistoryEntry(
                          actor: entry.actorName.trim().isEmpty
                              ? '-'
                              : entry.actorName,
                          timestamp: _formatHistoryTimestamp(entry.createdAt),
                          message: entry.displayMessage,
                          icon: entry.icon,
                        ),
                        isLast: isLast,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space24),
                  child: ZListSkeleton(itemCount: 3),
                ),
                error: (_, __) => _buildExpenseHistoryEmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseHistoryEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 18, 28),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No history available yet.',
          style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildHistoryTimelineEntry(
    _ExpenseHistoryEntry entry, {
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Center(
                  child: Icon(
                    entry.icon,
                    size: 13,
                    color: AppTheme.warningOrange,
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 1, height: 88, color: AppTheme.borderLight),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                runSpacing: 4,
                children: [
                  Text(
                    entry.actor,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '• ${entry.timestamp}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.message,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatHistoryTimestamp(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString().padLeft(4, '0');
    final hour24 = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$day-$month-$year ${hour12.toString().padLeft(2, '0')}:$minute $suffix';
  }

  Widget _buildStandardOverviewContent(ExpenseRecord r) {
    return Column(
      key: const ValueKey('standard-overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final bool stacked = constraints.maxWidth < 760;
            final details = SizedBox(
              width: stacked ? double.infinity : 430,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Amount',
                    style: AppTextStyles.label.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        _fmt(r.amount),
                        style: AppTextStyles.title.copyWith(
                          fontSize: 18,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'on ${r.date}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.status,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildExpenseAccountBadge(r),
                  const SizedBox(height: 36),
                  _buildDetailField('Paid Through', r.paidThrough),
                  _buildDetailField('Ref #', r.reference),
                  _buildDetailField('GST Treatment', r.gstTreatment),
                  _buildDetailField(
                    'Source of Supply',
                    _displayStateName(r.sourceOfSupply),
                  ),
                  _buildDetailField(
                    'Destination of Supply',
                    _displayStateName(r.destinationOfSupply),
                  ),
                  _buildDetailField('GST', r.gst),
                  _buildDetailField('Vendor Name', r.vendorName),
                  _buildDetailField('Customer Name', r.customerName),
                  _buildDetailValueOnly(r.notes),
                ],
              ),
            );

            final uploadCard = ExpenseAttachmentCardWidget(
              attachments: r.attachments,
              onDelete: _deleteAttachment,
              onUploadTap: _pickUploadExpenseFile,
              width: 246,
              height: 330,
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: 24), uploadCard],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 48),
                uploadCard,
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _buildJournalSection(r),
      ],
    );
  }

  Widget _buildA4ExpensePreview(ExpenseRecord r) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final billingStatusLabel = r.isBillable ? 'Billable' : 'Non-Billable';
    return Container(
      key: const ValueKey('pdf-overview'),
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          decoration: _paperDecoration(),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: _PdfCornerRibbon(
                    label: billingStatusLabel,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _pdfLogo(orgSettings),
                                const SizedBox(height: 18),
                                Text(
                                  orgSettings?.name.trim().isNotEmpty == true
                                      ? orgSettings!.name.trim()
                                      : 'ZABNIX PRIVATE LIMITED',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ..._buildPdfAddressLines(orgSettings),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 34),
                      Text(
                        'EXPENSE',
                        textAlign: TextAlign.center,
                        style: AppTheme.sectionHeader.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 44),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildPdfInfoRow('Expense Date', r.date),
                                _buildPdfInfoRow('Reference#', r.reference),
                                _buildPdfInfoRow(
                                  'Expense Account',
                                  r.expenseAccount,
                                ),
                                _buildPdfInfoRow('Currency Code', 'INR'),
                                _buildPdfInfoRow('Paid Through', r.paidThrough),
                                _buildPdfInfoRow(
                                  'Notes',
                                  r.notes.isEmpty ? r.reference : r.notes,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 36),
                          SizedBox(
                            width: 194,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 194,
                                  height: 122,
                                  color: AppTheme.successGreen,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Expense Amount',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.backgroundColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _fmt(r.amount),
                                        style: AppTextStyles.title.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.backgroundColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 148),
                                Text(
                                  'Authorized Signature',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPdfAddressLines(OrgSettings? orgSettings) {
    final lines = <String>[
      ..._formatPdfAddress(orgSettings?.resolvedPaymentStubAddress),
    ];
    final companyIdentity = orgSettings?.companyIdentityLine?.trim();
    final phone = orgSettings?.phone?.trim();
    final email = orgSettings?.email?.trim();
    if (companyIdentity != null && companyIdentity.isNotEmpty) {
      lines.add(companyIdentity);
    }
    if (phone != null && phone.isNotEmpty) lines.add(phone);
    if (email != null && email.isNotEmpty) lines.add(email);
    if (lines.isEmpty) {
      lines.addAll([
        'PERINTHALMANNA',
        'MALAPPURAM Kerala 679322',
        'India',
        'GSTIN 32AACCZ4912F1ZL',
        '8086355500',
        'zabnixprivatelimited@gmail.com',
      ]);
    }

    return lines
        .map(
          (line) => Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              line,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        )
        .toList();
  }

  List<String> _formatPdfAddress(String? rawAddress) {
    final address = rawAddress?.trim();
    if (address == null || address.isEmpty) {
      return const [];
    }

    if (address.startsWith('{')) {
      try {
        final decoded = json.jsonDecode(address);
        if (decoded is Map) {
          final read = (String key) {
            final value = decoded[key]?.toString().trim();
            if (value == null ||
                value.isEmpty ||
                value.toLowerCase() == 'null') {
              return null;
            }
            return value;
          };

          final lines = <String>[
            ...[
              read('attention'),
              read('street1'),
              read('street2'),
              read('street'),
              read('place'),
            ].whereType<String>(),
          ];

          final city = read('city');
          final district = read('district_name');
          final state = read('state_name') ?? read('state');
          final zip = read('pincode') ?? read('zip_code') ?? read('zip');
          final country = read('country');

          final locality = [
            city,
            district,
          ].whereType<String>().toSet().join(' ');
          final region = [state, zip].whereType<String>().join(' ');

          if (locality.isNotEmpty && region.isNotEmpty) {
            lines.add('$locality $region');
          } else if (locality.isNotEmpty) {
            lines.add(locality);
          } else if (region.isNotEmpty) {
            lines.add(region);
          }

          if (country != null) {
            lines.add(country);
          }

          return lines;
        }
      } catch (_) {
        // Fall through to plain-text formatting.
      }
    }

    return address
        .split(RegExp(r'\r?\n|,'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.toLowerCase() != 'null')
        .toList();
  }

  Widget _buildPdfInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : AppTheme.borderLight,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 188,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppTheme.textBody,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: AppTheme.backgroundColor,
      boxShadow: [
        BoxShadow(
          color: AppTheme.textPrimary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _pdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 240,
        height: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _pdfLogoFallback(),
        ),
      );
    }
    return _pdfLogoFallback();
  }

  Widget _pdfLogoFallback() {
    return Container(
      width: 240,
      height: 96,
      color: AppTheme.textPrimary,
      child: Center(
        child: Text(
          'LOGO / LETTERHEAD',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.backgroundColor.withValues(alpha: 0.7),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            trimmedValue,
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailValueOnly(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        trimmedValue,
        style: AppTextStyles.body.copyWith(
          color: AppTheme.textBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildJournalSection(ExpenseRecord r) {
    final journalAsync = ref.watch(expenseJournalProvider(r.id));

    return Container(
      key: _journalSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journal',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: AppTheme.borderLight),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Amount is displayed in your base currency ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                color: AppTheme.successDark,
                child: Text(
                  'INR',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppTheme.backgroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          journalAsync.when(
            data: (entries) => _buildJournalTable(entries),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space24),
              child: ZTableSkeleton(rows: 3, columns: 4),
            ),
            error: (_, __) => Text(
              'Unable to load journal entries.',
              style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalTable(List<ExpenseJournalEntryModel> entries) {
    final totalDebit = entries.fold<double>(0, (sum, row) => sum + row.debit);
    final totalCredit = entries.fold<double>(0, (sum, row) => sum + row.credit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense',
          style: AppTextStyles.title.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            Container(
              height: 34,
              color: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Text(
                      'ACCOUNT',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'DEBIT',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'CREDIT',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Text(
                        'No journal entries posted yet.',
                        style: AppTextStyles.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int index = 0; index < entries.length; index++)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              index == 0 ? 8 : 4,
                              12,
                              index == entries.length - 1 ? 8 : 0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Text(
                                    entries[index].accountName,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmt(entries[index].debit),
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppTheme.textBody,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmt(entries[index].credit),
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppTheme.textBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  const Spacer(flex: 7),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _fmt(totalDebit),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _fmt(totalCredit),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftFooter(int totalCount) {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalCount);

    return Container(
      height: _footerHeight,
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pager = Container(
            height: AppTheme.inputHeight - 4,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<int>(
                  tooltip: 'Rows per page',
                  offset: const Offset(0, -160),
                  color: AppTheme.backgroundColor,
                  surfaceTintColor: AppTheme.backgroundColor,
                  onSelected: (val) async {
                    await _changePageSize(val);
                  },
                  itemBuilder: (ctx) => [10, 25, 50, 100, 200]
                      .map(
                        (val) => PopupMenuItem<int>(
                          value: val,
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: _HoverPopupMenuItem(label: '$val per page'),
                        ),
                      )
                      .toList(),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveringRowsPerPage = true),
                    onExit: (_) => setState(() => _hoveringRowsPerPage = false),
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: _hoveringRowsPerPage
                          ? AppTheme.bgDisabled
                          : AppTheme.bgLight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.settings,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_rowsPerPage per page',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
                Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _hoveringPrevPage = true),
                        onExit: (_) =>
                            setState(() => _hoveringPrevPage = false),
                        cursor: _currentPage > 1
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: _currentPage > 1
                              ? () async => _changePage(_currentPage - 1)
                              : null,
                          child: Container(
                            width: 18,
                            height: double.infinity,
                            color: _hoveringPrevPage && _currentPage > 1
                                ? AppTheme.bgLight
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: _currentPage > 1
                                  ? AppTheme.primaryBlueDark
                                  : AppTheme.borderMid,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 52),
                        alignment: Alignment.center,
                        child: Text(
                          totalCount == 0
                              ? '0 - 0'
                              : '${startIndex + 1} - $endIndex',
                          style: AppTheme.metaHelper.copyWith(
                            color: AppTheme.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _hoveringNextPage = true),
                        onExit: (_) =>
                            setState(() => _hoveringNextPage = false),
                        cursor:
                            _currentPage <
                                ref.watch(expensesProvider).totalPages
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap:
                              _currentPage <
                                  ref.watch(expensesProvider).totalPages
                              ? () async => _changePage(_currentPage + 1)
                              : null,
                          child: Container(
                            width: 18,
                            height: double.infinity,
                            color:
                                _hoveringNextPage &&
                                    _currentPage <
                                        ref.watch(expensesProvider).totalPages
                                ? AppTheme.bgLight
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color:
                                  _currentPage <
                                      ref.watch(expensesProvider).totalPages
                                  ? AppTheme.primaryBlueDark
                                  : AppTheme.borderMid,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Total Count: ',
                      style: AppTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ZerpaiLinkText(
                    text: _showTotalCount ? '$totalCount' : 'View',
                    style: AppTheme.tableCell.copyWith(
                      color: AppTheme.primaryBlueDark,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: () =>
                        setState(() => _showTotalCount = !_showTotalCount),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerLeft, child: pager),
            ],
          );
        },
      ),
    );
  }

  List<StateLookupModel> get _stateCatalog =>
      ref.watch(expensesStatesProvider('IN')).asData?.value ??
      const <StateLookupModel>[];

  String? _normalizeStateName(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    final bracketSeparatorIndex = value.indexOf('] - ');
    if (value.startsWith('[') && bracketSeparatorIndex != -1) {
      return value.substring(bracketSeparatorIndex + 4).trim();
    }
    return value;
  }

  String _displayStateName(String value) {
    final normalized = _normalizeStateName(value)?.trim();
    if (normalized == null || normalized.isEmpty) {
      return value;
    }
    for (final option in _stateCatalog) {
      if (option.name.toLowerCase() == normalized.toLowerCase() ||
          option.code.toLowerCase() == normalized.toLowerCase() ||
          option.displayLabel.toLowerCase() == normalized.toLowerCase()) {
        return option.name;
      }
    }
    return normalized;
  }
}

class _PdfCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PdfCornerRibbon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 29,
            left: -41,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 27,
            left: -43,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.backgroundColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(
                        color: AppTheme.textPrimary.withValues(alpha: 0.45),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExpenseListCard extends StatefulWidget {
  final ExpenseRecord record;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;

  const _ExpenseListCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
    required this.onChanged,
  });

  @override
  State<_ExpenseListCard> createState() => _ExpenseListCardState();
}

class _ExpenseListCardState extends State<_ExpenseListCard> {
  bool _isHovered = false;
  static const double _attachmentSlotWidth = 16;
  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final formatted = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\u20B9$formatted.$decPart';
  }

  Widget _buildMileageExpenseAccountBlock() {
    final style = AppTextStyles.body.copyWith(
      color: AppTheme.primaryBlueDark,
      fontWeight: FontWeight.w600,
    );
    return ExpenseMileageAccountInline(record: widget.record, style: style);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppTheme.selectionActiveBg
        : (_isHovered ? AppTheme.bgLight : AppTheme.backgroundColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: widget.record.isSelected,
                        onChanged: widget.onChanged,
                        activeColor: AppTheme.primaryBlue,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMileageExpenseAccountBlock(),
                          const SizedBox(height: 8),
                          Text(
                            widget.record.date,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(widget.record.amount),
                          style: AppTextStyles.body.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: _attachmentSlotWidth,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: widget.record.hasAttachments
                                ? const Icon(
                                    LucideIcons.paperclip,
                                    size: 12,
                                    color: AppTheme.textSecondary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverPopupMenuItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  const _HoverPopupMenuItem({required this.label, this.icon});

  @override
  State<_HoverPopupMenuItem> createState() => _HoverPopupMenuItemState();
}

class _HoverPopupMenuItemState extends State<_HoverPopupMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? AppTheme.primaryBlueDark : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 14,
                color: _isHovered
                    ? AppTheme.backgroundColor
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _isHovered
                    ? AppTheme.backgroundColor
                    : AppTheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SubMenuType { none, sortBy, import, export }

class _MoreMenuDropdownContent extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onResetWidths;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onRefresh;
  final _SubMenuType activeSubMenu;
  final ValueChanged<_SubMenuType> onSubMenuChanged;
  final VoidCallback onImport;
  final VoidCallback onExportExpenses;
  final VoidCallback onExportCurrentView;

  const _MoreMenuDropdownContent({
    required this.onClose,
    required this.onResetWidths,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onRefresh,
    required this.activeSubMenu,
    required this.onSubMenuChanged,
    required this.onImport,
    required this.onExportExpenses,
    required this.onExportCurrentView,
  });

  @override
  State<_MoreMenuDropdownContent> createState() =>
      _MoreMenuDropdownContentState();
}

class _MoreMenuDropdownContentState extends State<_MoreMenuDropdownContent> {
  static const double _menuTopInset = 4;
  static const double _menuRowHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainMenu(),
        if (widget.activeSubMenu != _SubMenuType.none) ...[
          const SizedBox(width: 4),
          Padding(
            padding: EdgeInsets.only(top: _subMenuTopOffset()),
            child: _buildSubMenu(),
          ),
        ],
      ],
    );
  }

  double _subMenuTopOffset() {
    return switch (widget.activeSubMenu) {
      _SubMenuType.export => (_menuRowHeight * 2) - _menuTopInset,
      _ => 0,
    };
  }

  Widget _buildMainMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.sortBy),
            child: ExpensesMoreMenuItem(
              icon: Icons.swap_vert,
              label: 'Sort by',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.sortBy,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.import),
            child: ExpensesMoreMenuItem(
              icon: Icons.file_download_outlined,
              label: 'Import Expenses',
              isActive: widget.activeSubMenu == _SubMenuType.import,
              onTap: () {
                widget.onClose();
                widget.onImport();
              },
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.export),
            child: ExpensesMoreMenuItem(
              icon: Icons.file_upload_outlined,
              label: 'Export',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.export,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.none),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpensesMoreMenuItem(
                  icon: Icons.list,
                  label: 'Expense Category',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                ExpensesMoreMenuItem(
                  icon: Icons.settings,
                  label: 'Preferences',
                  onTap: widget.onClose,
                ),
                ExpensesMoreMenuItem(
                  icon: Icons.splitscreen,
                  label: 'Manage Custom Fields',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                ExpensesMoreMenuItem(
                  icon: Icons.refresh,
                  label: 'Refresh List',
                  onTap: () {
                    widget.onClose();
                    widget.onRefresh();
                  },
                ),
                ExpensesMoreMenuItem(
                  icon: Icons.settings_backup_restore,
                  label: 'Reset Column Width',
                  onTap: widget.onResetWidths,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSubMenu() {
    switch (widget.activeSubMenu) {
      case _SubMenuType.sortBy:
        return ExpensesMoreSubMenuPanel(
          children: [
            _buildSortItem('date', 'Date'),
            _buildSortItem('expenseAccount', 'Expense Account'),
            _buildSortItem('reference', 'Reference#'),
            _buildSortItem('vendorName', 'Vendor Name'),
            _buildSortItem('customerName', 'Customer Name'),
            _buildSortItem('amount', 'Amount'),
            _buildSortItem('created', 'Created Time'),
          ],
        );
      case _SubMenuType.export:
        return ExpensesMoreSubMenuPanel(
          children: [
            ExpensesMoreSubMenuItem(
              label: 'Export Expenses',
              onTap: () {
                widget.onClose();
                widget.onExportExpenses();
              },
            ),
            ExpensesMoreSubMenuItem(
              label: 'Export Current View',
              onTap: () {
                widget.onClose();
                widget.onExportCurrentView();
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSortItem(String field, String label) {
    final isSelected = widget.sortField == field;
    IconData? icon;
    if (isSelected) {
      icon = widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
    } else if (field == 'date') {
      icon = Icons.arrow_downward;
    } else {
      icon = Icons.arrow_upward;
    }

    return ExpensesMoreSubMenuItem(
      label: label,
      rightIcon: icon,
      isSelected: isSelected,
      onTap: () {
        final asc = isSelected ? !widget.sortAscending : true;
        widget.onSort(field, asc);
        widget.onClose();
      },
    );
  }
}

class _HoverToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _HoverToolbarButton({
    required this.icon,
    required this.label,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  State<_HoverToolbarButton> createState() => _HoverToolbarButtonState();
}

class _HoverToolbarButtonState extends State<_HoverToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: AppTheme.textPrimary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(
                  widget.trailingIcon,
                  size: 14,
                  color: AppTheme.textPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineActionSquare extends StatelessWidget {
  const _OutlineActionSquare({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
          color: AppTheme.backgroundColor,
        ),
        child: Icon(icon, size: 16, color: color ?? AppTheme.textPrimary),
      ),
    );
  }
}

class _FilledActionSquare extends StatelessWidget {
  const _FilledActionSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.successGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: AppTheme.backgroundColor),
      ),
    );
  }
}

class _HoverMoreButtonChild extends StatefulWidget {
  const _HoverMoreButtonChild();

  @override
  State<_HoverMoreButtonChild> createState() => _HoverMoreButtonChildState();
}

class _HoverMoreButtonChildState extends State<_HoverMoreButtonChild> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          LucideIcons.moreHorizontal,
          size: 15,
          color: AppTheme.textBody,
        ),
      ),
    );
  }
}

class _AssociateTagsDialog extends StatefulWidget {
  const _AssociateTagsDialog({
    required this.initialValues,
    required this.labels,
    required this.options,
  });

  final Map<String, String?> initialValues;
  final List<String> labels;
  final List<String> options;

  @override
  State<_AssociateTagsDialog> createState() => _AssociateTagsDialogState();
}

class _AssociateTagsDialogState extends State<_AssociateTagsDialog> {
  static const double _fieldHeight = 32.0;
  late final Map<String, String?> _values = Map<String, String?>.from(
    widget.initialValues,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Associate Tags',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: widget.labels
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                child: Text(
                                  label,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: FormDropdown<String>(
                                  value: _values[label],
                                  items: widget.options,
                                  hint: 'None',
                                  placeholder: 'None',
                                  showSearch: false,
                                  height: _fieldHeight,
                                  onChanged: (value) {
                                    setState(() => _values[label] = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () {
                      Navigator.of(context).pop(_values);
                    },
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarActionText extends StatefulWidget {
  const _SidebarActionText({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_SidebarActionText> createState() => _SidebarActionTextState();
}

class _SidebarActionTextState extends State<_SidebarActionText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            color: _hovered ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _ExpenseHistoryEntry {
  const _ExpenseHistoryEntry({
    required this.actor,
    required this.timestamp,
    required this.message,
    required this.icon,
  });

  final String actor;
  final String timestamp;
  final String message;
  final IconData icon;
}
