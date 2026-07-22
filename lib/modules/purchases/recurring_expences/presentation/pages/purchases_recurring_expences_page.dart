import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/responsive/responsive_table_shell.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../config/recurring_expense_constants.dart';
import '../../config/recurring_expense_routes.dart';
import '../../config/recurring_expense_table_config.dart';
import '../../models/bulk_update_recurring_expense_request.dart';
import '../../models/recurring_expense_audit_history_model.dart';
import '../../models/recurring_expense_details_model.dart';
import '../../models/recurring_expense_enums.dart';
import '../../models/recurring_expense_request_model.dart';
import '../../models/recurring_expense_response_model.dart';
import '../../providers/recurring_expense_provider.dart';
import '../dialogs/recurring_expense_bulk_update_dialog.dart';
import '../models/recurring_expense_search_filters.dart';
import '../widgets/recurring_expense_hover_popup_menu_item.dart';
import '../widgets/recurring_expense_model.dart';
import '../widgets/recurring_expense_details_widget.dart';
import '../widgets/recurring_expense_overview_selection_ribbon.dart';
import '../widgets/recurring_expense_selection_ribbon.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import '../widgets/recurring_expense_filter_dropdown.dart';

const _recurringExpenseFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'all'),
  FavoriteFilterOption(label: 'Active', value: 'active'),
  FavoriteFilterOption(label: 'Stopped', value: 'stopped'),
  FavoriteFilterOption(label: 'Expired', value: 'expired'),
];

class PurchasesRecurringExpensesPage extends ConsumerStatefulWidget {
  const PurchasesRecurringExpensesPage({super.key});

  @override
  ConsumerState<PurchasesRecurringExpensesPage> createState() =>
      _PurchasesRecurringExpensesPageState();
}

class _PurchasesRecurringExpensesPageState
    extends ConsumerState<PurchasesRecurringExpensesPage> {
  bool _allSelected = false;
  final Set<String> _selectedProfileIds = {};
  String? _hoveredRowId;
  FavoriteFilterOption _activeOption = _recurringExpenseFilterOptions.first;
  String get _selectedProfileFilter => _activeOption.value;
  bool _clipTableText = true;
  String _sortFieldLabel = 'Profile Name';
  bool _sortAscending = true;
  bool _isDetailActionLoading = false;
  bool _isBulkStatusActionLoading = false;
  bool _showTotalCount = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;
  int _currentPage = 1;
  int _pageSize = 100;
  int? _lastKnownTotalCount;
  int? _lastKnownTotalPages;
  String? _pendingDetailSyncSignature;
  String? _appliedDetailSyncSignature;
  RecurringExpenseSearchFilters _searchFilters =
      const RecurringExpenseSearchFilters();
  List<RecurringExpenseProfile> _profiles = <RecurringExpenseProfile>[];

  final List<ColumnConfig> _columns = buildRecurringExpenseColumns();

  final ValueNotifier<String?> _viewSelectorHoveredNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _moreMenuHoveredNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _moreSubmenuHoveredNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> _rightPaneMoreMenuHoveredNotifier =
      ValueNotifier<String?>(null);
  final LayerLink _moreMenuLayerLink = LayerLink();
  OverlayEntry? _moreMenuOverlay;
  String? _activeMoreSubmenu;
  static const double _moreMenuSubmenuGap = 4.0;
  static const double _exportSubmenuTopOffset = 101.0;
  static const double _tableHeaderHeight = 42.0;
  static const double _tableRowHeightClipped = 56.0;
  static const double _tableRowHeightWrapped = 84.0;
  static const double _paginationFooterHeight = 76.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _removeMoreMenuOverlay();
    _viewSelectorHoveredNotifier.dispose();
    _moreMenuHoveredNotifier.dispose();
    _moreSubmenuHoveredNotifier.dispose();
    _rightPaneMoreMenuHoveredNotifier.dispose();
    super.dispose();
  }

  RecurringExpenseRequest _listRequest() {
    final filters = _searchFilters;
    return RecurringExpenseRequest(
      page: _currentPage,
      limit: _pageSize,
      profileName: filters.name.trim().isEmpty ? null : filters.name.trim(),
      status:
          filters.status ??
          (_selectedProfileFilter == 'all'
              ? null
              : _scopeFilterToStatus(_selectedProfileFilter)),
      notes: filters.notes.trim().isEmpty ? null : filters.notes.trim(),
      vendorId: filters.vendor,
      customerId: filters.customerName,
      expenseAccountId: filters.expenseAccount,
      gstTreatment: filters.gstTreatment,
      sourceOfSupply: filters.sourceOfSupply,
      destinationOfSupply: filters.destinationOfSupply,
      taxId: filters.tax,
      startDateFrom: _formatQueryDate(filters.startDateFrom),
      startDateTo: _formatQueryDate(filters.startDateTo),
      endDateFrom: _formatQueryDate(filters.endDateFrom),
      endDateTo: _formatQueryDate(filters.endDateTo),
      amountFrom: filters.totalFrom,
      amountTo: filters.totalTo,
      sortField: _sortFieldQueryValue(_sortFieldLabel),
      sortDirection: _sortAscending ? 'asc' : 'desc',
    );
  }

  String? _formatQueryDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _sortFieldQueryValue(String fieldLabel) {
    return switch (fieldLabel) {
      'Expense Account' => 'expense_account_name',
      'Vendor Name' => 'vendor_name',
      'Last Expense Date' => 'last_run_date',
      'Next Expense Date' => 'next_run_date',
      'Amount' => 'amount',
      'Created Time' => 'created_at',
      _ => 'profile_name',
    };
  }

  String _sortFieldLabelFromQueryValue(String? value) {
    return switch (value) {
      'expense_account_name' => 'Expense Account',
      'vendor_name' => 'Vendor Name',
      'last_run_date' => 'Last Expense Date',
      'next_run_date' => 'Next Expense Date',
      'amount' => 'Amount',
      'created_at' => 'Created Time',
      _ => 'Profile Name',
    };
  }

  void _syncProfilesFromBackend(List<RecurringExpenseProfile> profiles) {
    if (!mounted) {
      return;
    }
    setState(() {
      _profiles = profiles
          .map((RecurringExpenseProfile item) => item.copyWith())
          .toList();
      _selectedProfileIds.removeWhere(
        (String id) =>
            !_profiles.any((RecurringExpenseProfile item) => item.id == id),
      );
      final visibleCount = _profiles.length;
      _allSelected =
          visibleCount > 0 && _selectedProfileIds.length == visibleCount;
    });
  }

  void _syncDetailIntoProfiles(RecurringExpenseDetails details) {
    if (!mounted) {
      return;
    }

    final index = _profiles.indexWhere((item) => item.id == details.id);
    if (index < 0) {
      return;
    }

    final existing = _profiles[index];
    final nextProfile = existing.copyWith(
      profileName: details.profileName,
      repeatEvery: details.repeatEvery,
      repeatType: details.repeatType,
      startDate: details.startDate,
      endDate: details.endDate,
      neverExpires: details.neverExpires,
      nextRunDate: details.nextRunDate,
      lastRunDate: details.lastRunDate,
      status: details.status,
      expenseAccountId: details.expenseAccountId,
      amount: details.amount,
      currencyCode: details.currencyCode,
      paidThroughAccountId: details.paidThroughAccountId,
      expenseType: details.expenseType,
      hsnSacCode: details.hsnSacCode,
      vendorId: details.vendorId,
      gstTreatment: details.gstTreatment,
      sourceOfSupply: details.sourceOfSupply,
      destinationOfSupply: details.destinationOfSupply,
      reverseCharge: details.reverseCharge,
      taxId: details.taxId,
      amountTaxMode: details.amountTaxMode,
      invoiceNumber: details.invoiceNumber,
      notes: details.notes,
      customerId: details.customerId,
      expenseAccountName: details.expenseAccountName,
      paidThroughAccountName: details.paidThroughAccountName,
      vendorNameRaw: details.vendorNameRaw,
      customerNameRaw: details.customerNameRaw,
      isBillable: details.isBillable,
      autoCreate: details.autoCreate,
      createdBy: details.createdBy,
      updatedBy: details.updatedBy,
      createdAt: details.createdAt,
      updatedAt: details.updatedAt,
    );

    if (nextProfile.toJson().toString() == existing.toJson().toString()) {
      return;
    }

    setState(() {
      _profiles[index] = nextProfile;
    });
  }

  String _detailStatusLabel(RecurringExpenseStatus status) {
    return switch (status) {
      RecurringExpenseStatus.active => 'Active',
      RecurringExpenseStatus.stopped => 'Stopped',
      RecurringExpenseStatus.expired => 'Expired',
    };
  }

  Color _statusColor(RecurringExpenseStatus status) {
    return switch (status) {
      RecurringExpenseStatus.active => AppTheme.successDark,
      RecurringExpenseStatus.stopped => AppTheme.warningOrange,
      RecurringExpenseStatus.expired => AppTheme.warningOrange,
    };
  }

  Future<void> _refreshBackendData({String? detailId}) async {
    final request = _listRequest();
    ref.invalidate(recurringExpensesProvider(request));
    if (detailId != null && detailId.isNotEmpty) {
      ref.invalidate(recurringExpenseDetailsProvider(detailId));
      ref.invalidate(recurringExpenseHistoryProvider(detailId));
      ref.invalidate(recurringExpenseRunsProvider(detailId));
      ref.invalidate(recurringExpenseRelatedExpensesProvider(detailId));
    }

    final response = await ref.read(recurringExpensesProvider(request).future);
    _syncProfilesFromBackend(response.items);

    if (detailId != null && detailId.isNotEmpty) {
      final details = await ref.read(
        recurringExpenseDetailsProvider(detailId).future,
      );
      if (details != null) {
        _syncDetailIntoProfiles(details);
      }
    }
  }

  Future<void> _handleDetailAction(
    String action,
    RecurringExpenseProfile profile,
  ) async {
    if (action == 'delete') {
      await _deleteSelectedProfiles(<RecurringExpenseProfile>[
        profile,
      ], navigateToListAfterDelete: true);
      return;
    }

    if (action == 'create_expense') {
      final orgSystemId = RecurringExpenseModuleDefaults.orgSystemId;
      context.push(
        '/$orgSystemId/purchases/expenses/create?recurringId=${Uri.encodeComponent(profile.id)}',
      );
      return;
    }

    try {
      setState(() {
        _isDetailActionLoading = true;
      });

      if (action == 'start') {
        await ref.read(startRecurringExpenseProvider(profile.id).future);
      } else if (action == 'stop') {
        await ref.read(stopRecurringExpenseProvider(profile.id).future);
      } else {
        return;
      }

      if (!mounted) {
        return;
      }

      ErrorHandler.showSuccessSnackBar(
        context,
        action == 'start'
            ? 'Recurring expense started successfully.'
            : action == 'stop'
            ? 'Recurring expense stopped successfully.'
            : 'Expense created successfully.',
      );

      await _refreshBackendData(detailId: profile.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetailActionLoading = false;
        });
      }
    }
  }

  void _onNewPressed() {
    final orgSystemId = RecurringExpenseModuleDefaults.orgSystemId;
    final currentUri = GoRouterState.of(context).uri.toString();
    AppLogger.info(
      'Opened recurring expenses create page',
      module: 'purchases_recurring_expenses',
    );
    context.push(
      '/$orgSystemId${RecurringExpenseRoutes.create}?returnTo=${Uri.encodeComponent(currentUri)}',
    );
  }

  void _onEditPressed(RecurringExpenseProfile profile) {
    final orgSystemId = RecurringExpenseModuleDefaults.orgSystemId;
    final currentUri = GoRouterState.of(context).uri.toString();
    AppLogger.info(
      'Opened recurring expenses edit page',
      data: {'profileId': profile.id},
      module: 'purchases_recurring_expenses',
    );
    context.push(
      '/$orgSystemId${RecurringExpenseRoutes.create}?mode=edit&id=${Uri.encodeComponent(profile.id)}&returnTo=${Uri.encodeComponent(currentUri)}',
    );
  }

  void _openProfileDetails(
    String orgSystemId,
    RecurringExpenseProfile profile,
  ) {
    context.go(
      '/$orgSystemId${RecurringExpenseRoutes.list}?id=${Uri.encodeComponent(profile.id)}',
    );
  }

  void _setAllRowsSelected(
    bool selected,
    List<RecurringExpenseProfile> profiles,
  ) {
    setState(() {
      _allSelected = selected;
      if (selected) {
        _selectedProfileIds.addAll(profiles.map((p) => p.id));
      } else {
        _selectedProfileIds.clear();
      }
    });
    AppLogger.info(
      'Changed recurring expenses bulk row selection',
      data: {'selected': selected, 'selectedCount': _selectedProfileIds.length},
      module: 'purchases_recurring_expenses',
    );
  }

  void _setRowSelected(
    RecurringExpenseProfile profile,
    bool selected,
    int visibleRowCount,
  ) {
    setState(() {
      if (selected) {
        _selectedProfileIds.add(profile.id);
      } else {
        _selectedProfileIds.remove(profile.id);
      }
      _allSelected =
          visibleRowCount > 0 && _selectedProfileIds.length == visibleRowCount;
    });
    AppLogger.info(
      'Changed recurring expenses row selection',
      data: {
        'profileId': profile.id,
        'selected': selected,
        'selectedCount': _selectedProfileIds.length,
      },
      module: 'purchases_recurring_expenses',
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedProfileIds.clear();
      _allSelected = false;
    });
    AppLogger.info(
      'Cleared recurring expenses row selection',
      module: 'purchases_recurring_expenses',
    );
  }

  Future<bool> _confirmDelete(int count) async {
    return await showZerpaiConfirmationDialog(
          context,
          title: count == 1
              ? 'Delete Recurring Expense'
              : 'Delete Recurring Expenses',
          message: count == 1
              ? 'Are you sure you want to delete this recurring expense?'
              : 'Are you sure you want to delete the selected recurring expenses?',
        ) ==
        true;
  }

  Future<void> _deleteSelectedProfiles(
    List<RecurringExpenseProfile> profiles, {
    bool navigateToListAfterDelete = false,
  }) async {
    if (profiles.isEmpty) {
      return;
    }

    final confirmed = await _confirmDelete(profiles.length);
    if (!confirmed || !mounted) {
      return;
    }

    final deletedIds = profiles
        .map((RecurringExpenseProfile item) => item.id)
        .toSet();

    try {
      if (profiles.length == 1) {
        await ref.read(
          deleteRecurringExpenseProvider(profiles.first.id).future,
        );
      } else {
        await ref.read(
          deleteRecurringExpensesBulkProvider(deletedIds.toList()).future,
        );
      }

      await _refreshBackendData();
      if (!mounted) {
        return;
      }

      setState(() {
        _profiles.removeWhere((RecurringExpenseProfile item) {
          return deletedIds.contains(item.id);
        });
        _selectedProfileIds.removeWhere(deletedIds.contains);
        _allSelected =
            _profiles.isNotEmpty &&
            _selectedProfileIds.length == _profiles.length;
      });

      ErrorHandler.showSuccessSnackBar(
        context,
        profiles.length == 1
            ? 'Recurring expense deleted successfully.'
            : '${profiles.length} recurring expenses deleted successfully.',
      );

      final activeDetailId = GoRouterState.of(
        context,
      ).uri.queryParameters['id'];
      if (navigateToListAfterDelete ||
          (activeDetailId != null && deletedIds.contains(activeDetailId))) {
        context.go(
          '/${RecurringExpenseModuleDefaults.orgSystemId}${RecurringExpenseRoutes.list}',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(error),
      );
    }
  }

  Future<void> _openBulkUpdateDialog() async {
    AppLogger.info(
      'Opened recurring expenses bulk update dialog',
      data: {'selectedCount': _selectedProfileIds.length},
      module: 'purchases_recurring_expenses',
    );

    final result = await showDialog<RecurringExpenseBulkUpdateResult>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.72),
      builder: (context) => const RecurringExpenseBulkUpdateDialog(),
    );
    if (result == null) {
      AppLogger.info(
        'Closed recurring expenses bulk update dialog',
        module: 'purchases_recurring_expenses',
      );
      return;
    }

    final request = _buildBulkUpdateRequest(result);
    if (request == null) {
      return;
    }

    try {
      final response = await ref.read(
        bulkUpdateRecurringExpensesProvider(request).future,
      );
      if (!mounted) {
        return;
      }

      await _refreshBackendData();
      if (!mounted) {
        return;
      }

      if (response.updatedCount == 0) {
        ErrorHandler.showErrorSnackBar(
          context,
          'No recurring expenses were updated.',
        );
        return;
      }

      ErrorHandler.showSuccessSnackBar(
        context,
        response.updatedCount == 1
            ? 'Recurring expense updated successfully.'
            : '${response.updatedCount} recurring expenses updated successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(error),
      );
      return;
    }

    AppLogger.info(
      'Applied recurring expenses bulk update',
      data: {
        'field': result.field,
        'value': result.value,
        'selectedCount': _selectedProfileIds.length,
      },
      module: 'purchases_recurring_expenses',
    );
  }

  BulkUpdateRecurringExpenseRequest? _buildBulkUpdateRequest(
    RecurringExpenseBulkUpdateResult result,
  ) {
    final Map<String, dynamic> updateData = switch (result.field) {
      'Expense Account' => <String, dynamic>{
        'expense_account_id': result.value,
      },
      'Paid Through' => <String, dynamic>{
        'paid_through_account_id': result.value,
      },
      'End Date' => <String, dynamic>{'end_date': result.value},
      'Repeat Every'
          when result.repeatEvery != null && result.repeatType != null =>
        <String, dynamic>{
          'repeat_every': result.repeatEvery,
          'repeat_type': result.repeatType!.value,
        },
      'Notes' => <String, dynamic>{'notes': result.value},
      'Vendor' => <String, dynamic>{'vendor_id': result.value},
      'Customer' => <String, dynamic>{'customer_id': result.value},
      'Expense Type' => <String, dynamic>{'expense_type': result.value},
      'Billable' => <String, dynamic>{
        'is_billable': result.value == 'Check this option',
      },
      _ => const <String, dynamic>{},
    };

    if (updateData.isEmpty) {
      return null;
    }

    return BulkUpdateRecurringExpenseRequest(
      ids: _selectedProfileIds.toList(growable: false),
      updateData: updateData,
    );
  }

  Future<void> _applyBulkStatusAction(String action) async {
    final profiles = _profiles.where((item) {
      return _selectedProfileIds.contains(item.id);
    }).toList();
    if (profiles.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isBulkStatusActionLoading = true;
      });

      for (final profile in profiles) {
        if (action == 'start') {
          await ref.read(startRecurringExpenseProvider(profile.id).future);
        } else if (action == 'stop') {
          await ref.read(stopRecurringExpenseProvider(profile.id).future);
        }
      }

      await _refreshBackendData();
      if (!mounted) {
        return;
      }

      ErrorHandler.showSuccessSnackBar(
        context,
        action == 'start'
            ? 'Recurring expenses started successfully.'
            : 'Recurring expenses stopped successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBulkStatusActionLoading = false;
        });
      }
    }
  }

  void _hydrateProfilesFromCurrentResponse(
    AsyncValue<RecurringExpenseResponse> recurringExpensesAsync,
  ) {
    final items = recurringExpensesAsync.asData?.value.items;
    if (items == null || items.isEmpty || _profiles.isNotEmpty) {
      return;
    }

    final profiles = items
        .map((RecurringExpense item) => item.copyWith())
        .toList(growable: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _profiles.isNotEmpty) {
        return;
      }
      _syncProfilesFromBackend(profiles);
    });
  }

  String _detailSyncSignature(RecurringExpenseDetails details) {
    return jsonEncode(details.toJson());
  }

  void _scheduleDetailSync(RecurringExpenseDetails details) {
    final signature = _detailSyncSignature(details);
    if (_pendingDetailSyncSignature == signature ||
        _appliedDetailSyncSignature == signature) {
      return;
    }

    _pendingDetailSyncSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingDetailSyncSignature != signature) {
        return;
      }
      _pendingDetailSyncSignature = null;
      _syncDetailIntoProfiles(details);
      _appliedDetailSyncSignature = signature;
    });
  }

  void _onSelectionAction(String action) {
    if (action == 'bulk_update') {
      _openBulkUpdateDialog();
      return;
    }
    if (action == 'start' || action == 'stop') {
      _applyBulkStatusAction(action);
      return;
    }
    if (action == 'delete') {
      final profilesToDelete = _profiles.where((RecurringExpenseProfile item) {
        return _selectedProfileIds.contains(item.id);
      }).toList();
      _deleteSelectedProfiles(profilesToDelete);
      return;
    }
    AppLogger.info(
      'Selected recurring expenses bulk action',
      data: {'action': action, 'selectedCount': _selectedProfileIds.length},
      module: 'purchases_recurring_expenses',
    );
  }

  List<ColumnConfig> get _visibleColumns {
    final visibleColumns = _columns
        .where((column) => column.isVisible)
        .toList();
    visibleColumns.sort(
      (left, right) => left.orderIndex.compareTo(right.orderIndex),
    );
    return visibleColumns;
  }

  Map<String, double> _calculateColumnWidths(double availableWidth) {
    const double staticPrefixWidth = 12 + 28 + 10 + 20 + 24 + 40;

    double totalMinWidth = staticPrefixWidth.toDouble();
    double totalFlex = 0;
    final Map<String, double> minWidths = <String, double>{};

    for (final column in _visibleColumns) {
      final minWidth = recurringExpenseColumnWidths[column.id] ?? 120;
      minWidths[column.id] = minWidth;
      totalMinWidth += minWidth;
      totalFlex += minWidth;
    }

    final extraSpace = math.max(0.0, availableWidth - totalMinWidth);
    final results = <String, double>{};

    for (final column in _visibleColumns) {
      final minWidth = minWidths[column.id]!;
      final flex = totalFlex == 0 ? 0.0 : minWidth / totalFlex;
      results[column.id] = minWidth + (extraSpace * flex);
    }

    return results;
  }

  double _tableWidthFor(Map<String, double> columnWidths) {
    final columnsWidth = columnWidths.values.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    return 12 + 28 + 10 + 20 + 24 + columnsWidth + 40;
  }

  String _formatCurrency(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return '\u20B9${buffer.toString()}.${parts.last}';
  }

  String _scopeFilterToStatus(String scopeFilter) {
    return switch (scopeFilter.toLowerCase()) {
      'active' => RecurringExpenseStatus.active.value,
      'stopped' => RecurringExpenseStatus.stopped.value,
      'expired' => RecurringExpenseStatus.expired.value,
      _ => scopeFilter.toUpperCase(),
    };
  }

  void _updateListRoute(
    BuildContext context, {
    FavoriteFilterOption? filter,
    String? sortFieldLabel,
    bool? sortAscending,
  }) {
    final state = GoRouterState.of(context);
    final newParams = Map<String, String>.from(state.uri.queryParameters);
    final nextFilter = filter ?? _activeOption;
    final nextSortFieldLabel = sortFieldLabel ?? _sortFieldLabel;
    final nextSortAscending = sortAscending ?? _sortAscending;
    final nextSortField = _sortFieldQueryValue(nextSortFieldLabel);

    if (nextFilter.value == 'all') {
      newParams.remove('filter');
    } else {
      newParams['filter'] = nextFilter.value;
    }

    if (nextSortField == 'profile_name') {
      newParams.remove('sortField');
    } else {
      newParams['sortField'] = nextSortField;
    }

    if (nextSortAscending) {
      newParams.remove('sortDirection');
    } else {
      newParams['sortDirection'] = 'desc';
    }

    final uri = state.uri.replace(queryParameters: newParams);
    context.go(uri.toString());
  }

  void _updateRowsPerPage(int value) {
    if (value == _pageSize) {
      return;
    }
    setState(() {
      _pageSize = value;
      _currentPage = 1;
    });
  }

  Widget _buildPaginationFooter({
    required int totalCount,
    required int page,
    required int pageSize,
    required int totalPages,
    required int currentPageCount,
  }) {
    final int safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final int start = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final int end = totalCount == 0
        ? 0
        : (((page - 1) * pageSize) + currentPageCount).clamp(0, totalCount);
    final bool canGoPrevious = page > 1;
    final bool canGoNext = page < safeTotalPages;

    return SizedBox(
      width: double.infinity,
      child: Container(
        height: _paginationFooterHeight,
        decoration: const BoxDecoration(color: AppTheme.backgroundColor),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text('Total Count: ', style: AppTextStyles.body),
            GestureDetector(
              onTap: () => setState(() => _showTotalCount = !_showTotalCount),
              child: Text(
                _showTotalCount ? '$totalCount' : 'View',
                style: AppTheme.tableCell.copyWith(
                  color: AppTheme.primaryBlueDark,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: AppTheme.inputHeight,
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
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    onSelected: (value) {
                      if (value == pageSize) return;
                      _updateRowsPerPage(value);
                    },
                    itemBuilder: (ctx) => [10, 25, 50, 100, 200]
                        .map(
                          (value) => PopupMenuItem<int>(
                            value: value,
                            padding: EdgeInsets.zero,
                            height: 36,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$value per page',
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    child: MouseRegion(
                      onEnter: (_) =>
                          setState(() => _hoveringRowsPerPage = true),
                      onExit: (_) =>
                          setState(() => _hoveringRowsPerPage = false),
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: _hoveringRowsPerPage
                            ? AppTheme.bgDisabled
                            : AppTheme.bgLight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.settings,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pageSize per page',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringPrevPage = true),
                          onExit: (_) =>
                              setState(() => _hoveringPrevPage = false),
                          cursor: canGoPrevious
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: canGoPrevious
                                ? () => setState(() => _currentPage--)
                                : null,
                            child: Container(
                              width: 20,
                              height: double.infinity,
                              color: _hoveringPrevPage && canGoPrevious
                                  ? AppTheme.bgLight
                                  : Colors.transparent,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_left,
                                size: 18,
                                color: canGoPrevious
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.borderMid,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 58),
                          alignment: Alignment.center,
                          child: Text(
                            totalCount == 0 ? '0 - 0' : '$start - $end',
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.textBody,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringNextPage = true),
                          onExit: (_) =>
                              setState(() => _hoveringNextPage = false),
                          cursor: canGoNext
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: canGoNext
                                ? () => setState(() => _currentPage++)
                                : null,
                            child: Container(
                              width: 20,
                              height: double.infinity,
                              color: _hoveringNextPage && canGoNext
                                  ? AppTheme.bgLight
                                  : Colors.transparent,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: canGoNext
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPaginationFooter({
    required int totalCount,
    required int page,
    required int pageSize,
    required int currentPageCount,
  }) {
    final int start = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final int end = totalCount == 0
        ? 0
        : (((page - 1) * pageSize) + currentPageCount).clamp(0, totalCount);
    final bool canGoPrevious = page > 1;
    final bool canGoNext = end < totalCount;

    return Container(
      height: _paginationFooterHeight,
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
                  onSelected: (value) {
                    if (value == pageSize) return;
                    _updateRowsPerPage(value);
                  },
                  itemBuilder: (ctx) => [10, 25, 50, 100, 200]
                      .map(
                        (value) => PopupMenuItem<int>(
                          value: value,
                          padding: EdgeInsets.zero,
                          height: 36,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$value per page',
                                style: AppTextStyles.body,
                              ),
                            ),
                          ),
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
                          Text('$pageSize per page', style: AppTextStyles.body),
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
                        cursor: canGoPrevious
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: canGoPrevious
                              ? () => setState(() => _currentPage--)
                              : null,
                          child: Container(
                            width: 18,
                            height: double.infinity,
                            color: _hoveringPrevPage && canGoPrevious
                                ? AppTheme.bgLight
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: canGoPrevious
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
                          totalCount == 0 ? '0 - 0' : '$start - $end',
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
                        cursor: canGoNext
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: canGoNext
                              ? () => setState(() => _currentPage++)
                              : null,
                          child: Container(
                            width: 18,
                            height: double.infinity,
                            color: _hoveringNextPage && canGoNext
                                ? AppTheme.bgLight
                                : Colors.transparent,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: canGoNext
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

  // Future<void> _openAdvancedSearchDialog() async {
  //   AppLogger.info(
  //     'Opened recurring expenses advanced search dialog',
  //     module: 'purchases_recurring_expenses',
  //   );

  //   final filters = await showDialog<RecurringExpenseSearchFilters>(
  //     context: context,
  //     barrierColor: AppTheme.textPrimary.withValues(alpha: 0.72),
  //     builder: (context) =>
  //         RecurringExpenseSearchDialog(initialFilters: _searchFilters),
  //   );

  //   if (filters == null) {
  //     AppLogger.info(
  //       'Closed recurring expenses advanced search dialog',
  //       module: 'purchases_recurring_expenses',
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _searchFilters = filters;
  //     _selectedProfileIds.clear();
  //     _allSelected = false;
  //   });
  //   AppLogger.info(
  //     'Applied recurring expenses advanced search filters',
  //     data: filters.toLogData(),
  //     module: 'purchases_recurring_expenses',
  //   );
  // }

  void _applySort(String fieldLabel) {
    setState(() {
      if (_sortFieldLabel == fieldLabel) {
        _sortAscending = !_sortAscending;
      } else {
        _sortFieldLabel = fieldLabel;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
    AppLogger.info(
      'Changed recurring expenses table sort',
      data: {
        'field': fieldLabel,
        'direction': _sortAscending ? 'ascending' : 'descending',
      },
      module: 'purchases_recurring_expenses',
    );
    _updateListRoute(
      context,
      sortFieldLabel: _sortFieldLabel,
      sortAscending: _sortAscending,
    );
  }

  Future<void> _openColumnCustomizer() async {
    AppLogger.info(
      'Opened recurring expenses column customizer',
      module: 'purchases_recurring_expenses',
    );

    final updated = await showDialog<List<ColumnConfig>>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.7),
      builder: (dialogContext) => ColumnCustomizerDialog(
        columns: _columns.map(cloneRecurringExpenseColumn).toList(),
        onSave: (columns) {
          Navigator.of(
            dialogContext,
          ).pop(columns.map(cloneRecurringExpenseColumn).toList());
        },
      ),
    );

    if (updated == null) {
      return;
    }

    setState(() {
      _columns
        ..clear()
        ..addAll(updated);
      _columns.sort(
        (left, right) => left.orderIndex.compareTo(right.orderIndex),
      );
    });
    AppLogger.info(
      'Saved recurring expenses visible columns',
      data: {
        'visibleColumns': _columns
            .where((column) => column.isVisible)
            .map((column) => column.id)
            .toList(),
      },
      module: 'purchases_recurring_expenses',
    );
  }

  Widget _buildHeaderCell(
    ColumnConfig column,
    Map<String, double> columnWidths,
  ) {
    final isProfile = column.id == 'profile';
    final isAmount = column.id == 'amount';

    return SizedBox(
      width: columnWidths[column.id] ?? 120,
      child: Align(
        alignment: isAmount ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: isAmount
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                column.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            if (isProfile) ...[
              const SizedBox(width: 4),
              InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () => _applySort('Profile Name'),
                child: Icon(
                  _sortAscending
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  size: 14,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _cellTextForColumn(
    RecurringExpenseProfile profile,
    ColumnConfig column,
  ) {
    switch (column.id) {
      case 'profile':
        return profile.name;
      case 'expense':
        return profile.expenseAccount;
      case 'vendor':
        return profile.vendorName;
      case 'frequency':
        return profile.frequency;
      case 'last':
        return profile.lastExpenseDate;
      case 'next':
        return profile.nextExpenseDate;
      case 'status':
        return profile.statusText;
      case 'amount':
        return _formatCurrency(profile.amount);
      case 'customer':
        return '';
      default:
        return '';
    }
  }

  Widget _buildBodyCell(
    RecurringExpenseProfile profile,
    ColumnConfig column,
    Map<String, double> columnWidths,
  ) {
    final isProfile = column.id == 'profile';
    final isStatus = column.id == 'status';
    final isAmount = column.id == 'amount';
    final maxLines = _clipTableText ? 1 : 2;

    return SizedBox(
      width: columnWidths[column.id] ?? 120,
      child: Align(
        alignment: isAmount ? Alignment.centerRight : Alignment.centerLeft,
        child: isAmount
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: ZCurrencyDisplay(
                  amount: profile.amount,
                  style: AppTextStyles.body.copyWith(
                    height: 1.7,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            : Text(
                _cellTextForColumn(profile, column),
                maxLines: maxLines,
                overflow: _clipTableText
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
                style: AppTextStyles.body.copyWith(
                  height: 1.7,
                  color: isProfile
                      ? AppTheme.infoBlue
                      : isStatus
                      ? _statusColor(profile.status)
                      : AppTheme.textPrimary,
                  fontWeight: isProfile || isStatus
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
      ),
    );
  }

  String get _emptyProfileMessage {
    return _searchFilters.hasActive
        ? 'There is no data'
        : _selectedProfileFilter == 'active'
        ? 'There are no active profiles'
        : _selectedProfileFilter == 'stopped'
        ? 'There are no stopped profiles'
        : _selectedProfileFilter == 'expired'
        ? 'There are no expired profiles'
        : 'There are no profiles';
  }

  Widget _buildEmptyTableStructure(
    List<RecurringExpenseProfile> filteredExpenses,
    Map<String, double> columnWidths,
  ) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ZTableHeaderMenu(
                  wrapText: !_clipTableText,
                  onWrapChange: (wrapText) {
                    setState(() => _clipTableText = !wrapText);
                    AppLogger.info(
                      'Changed recurring expenses table text mode',
                      data: {'mode': wrapText ? 'wrap' : 'clip'},
                      module: 'purchases_recurring_expenses',
                    );
                  },
                  onCustomize: _openColumnCustomizer,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: false,
                    onChanged: (_) =>
                        _setAllRowsSelected(false, filteredExpenses),
                    activeColor: AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(width: 24),
                for (final column in _visibleColumns)
                  _buildHeaderCell(column, columnWidths),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 21),
                  child: Text(
                    _emptyProfileMessage,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrappedTable(
    String orgSystemId,
    List<RecurringExpenseProfile> filteredExpenses,
    Map<String, double> columnWidths,
    double tableWidth,
    double availableHeight,
    Widget? footer,
  ) {
    final double rowHeight = _clipTableText
        ? _tableRowHeightClipped
        : _tableRowHeightWrapped;
    final bool showFooter = footer != null;

    return SizedBox(
      width: tableWidth,
      height: availableHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: _tableHeaderHeight,
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ZTableHeaderMenu(
                  wrapText: !_clipTableText,
                  onWrapChange: (wrapText) {
                    setState(() => _clipTableText = !wrapText);
                    AppLogger.info(
                      'Changed recurring expenses table text mode',
                      data: {'mode': wrapText ? 'wrap' : 'clip'},
                      module: 'purchases_recurring_expenses',
                    );
                  },
                  onCustomize: _openColumnCustomizer,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _allSelected,
                    onChanged: (val) =>
                        _setAllRowsSelected(val ?? false, filteredExpenses),
                    activeColor: AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(width: 24),
                for (final column in _visibleColumns)
                  _buildHeaderCell(column, columnWidths),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final profile = filteredExpenses[index];
                    final isRowSelected = _selectedProfileIds.contains(
                      profile.id,
                    );
                    return MouseRegion(
                      onEnter: (_) =>
                          setState(() => _hoveredRowId = profile.id),
                      onExit: (_) => setState(() => _hoveredRowId = null),
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: rowHeight,
                        decoration: BoxDecoration(
                          color: isRowSelected
                              ? AppTheme.selectionActiveBg
                              : (_hoveredRowId == profile.id
                                    ? AppTheme.bgHover
                                    : AppTheme.backgroundColor),
                          border: const Border(
                            bottom: BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                        child: InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () =>
                              _openProfileDetails(orgSystemId, profile),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const SizedBox(width: 28),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isRowSelected,
                                  onChanged: (val) => _setRowSelected(
                                    profile,
                                    val ?? false,
                                    filteredExpenses.length,
                                  ),
                                  activeColor: AppTheme.primaryBlueDark,
                                ),
                              ),
                              const SizedBox(width: 24),
                              for (final column in _visibleColumns)
                                _buildBodyCell(profile, column, columnWidths),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (showFooter) footer,
        ],
      ),
    );
  }

  Widget _buildViewSelector(
    BuildContext context, {
    required bool isDetailsMode,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: RecurringExpenseFilterDropdown(
        moduleName: 'recurring_expences',
        options: _recurringExpenseFilterOptions,
        selectedOption: _activeOption,
        isCompact: isDetailsMode,
        onChanged: (opt) {
          setState(() {
            _activeOption = opt;
            _currentPage = 1;
          });
          AppLogger.info(
            'Changed recurring expenses profile filter',
            data: {'filter': opt.value},
            module: 'purchases_recurring_expenses',
          );
          _updateListRoute(context, filter: opt);
        },
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, {required bool isCompact}) {
    return CompositedTransformTarget(
      link: _moreMenuLayerLink,
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => _toggleMoreMenuOverlay(isCompact: isCompact),
        child: Container(
          width: isCompact ? 28 : recurringExpensesPageMoreMenuSize,
          height: isCompact ? 28 : recurringExpensesPageMoreMenuSize,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.more_horiz,
              color: AppTheme.textPrimary,
              size: isCompact ? 16 : 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeaderNewButton() {
    return SizedBox(
      width: recurringExpensesPageActionButtonWidth,
      height: recurringExpensesPageActionButtonHeight,
      child: ZButton.primary(
        label: 'New',
        icon: Icons.add,
        onPressed: _onNewPressed,
      ),
    );
  }

  Widget _buildPageHeaderActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageHeaderNewButton(),
        const SizedBox(width: 8),
        _buildMoreMenu(context, isCompact: false),
      ],
    );
  }

  Widget _buildMainToolbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildViewSelector(context, isDetailsMode: false)),
          const SizedBox(width: 16),
          _buildPageHeaderActions(context),
        ],
      ),
    );
  }

  void _toggleMoreMenuOverlay({required bool isCompact}) {
    if (_moreMenuOverlay == null) {
      _openMoreMenuOverlay(isCompact: isCompact);
    } else {
      _closeMoreMenuOverlay();
    }
  }

  void _openMoreMenuOverlay({required bool isCompact}) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null || _moreMenuOverlay != null) {
      return;
    }

    _moreMenuHoveredNotifier.value = null;
    _moreSubmenuHoveredNotifier.value = null;
    _activeMoreSubmenu = null;
    AppLogger.info(
      'Opened recurring expenses more menu',
      module: 'purchases_recurring_expenses',
    );

    _moreMenuOverlay = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, overlaySetState) {
          void setSubmenu(String? submenu) {
            overlaySetState(() {
              _activeMoreSubmenu = submenu;
              _moreSubmenuHoveredNotifier.value = null;
            });
          }

          void applySortFromOverlay(String value) {
            _applySort(value);
            overlaySetState(() {});
          }

          const mainMenuWidth = 274.0;
          final triggerBox = _moreMenuLayerLink.leaderSize;
          final triggerWidth = triggerBox?.width ?? (isCompact ? 28.0 : 38.0);
          final horizontalOffset = triggerWidth - mainMenuWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeMoreMenuOverlay,
                ),
              ),
              CompositedTransformFollower(
                link: _moreMenuLayerLink,
                offset: Offset(horizontalOffset, isCompact ? 32 : 42),
                showWhenUnlinked: false,
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMoreMenuPanel(setSubmenu),
                      if (_activeMoreSubmenu != null)
                        const SizedBox(width: _moreMenuSubmenuGap),
                      if (_activeMoreSubmenu == 'sort')
                        _buildMoreSubmenu(
                          width: 204,
                          values: const [
                            'Profile Name',
                            'Expense Account',
                            'Vendor Name',
                            'Last Expense Date',
                            'Next Expense Date',
                            'Amount',
                            'Created Time',
                          ],
                          activeValue: _sortFieldLabel,
                          trailingIcon: _sortAscending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          onItemTap: applySortFromOverlay,
                        ),
                      if (_activeMoreSubmenu == 'export')
                        Padding(
                          padding: const EdgeInsets.only(
                            top: _exportSubmenuTopOffset,
                          ),
                          child: _buildMoreSubmenu(
                            width: 242,
                            values: const [
                              'Export Recurring Expenses',
                              'Export Current View',
                            ],
                            activeValue: 'Export Recurring Expenses',
                            onItemTap: _logAndCloseMoreMenu,
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
    );
    overlayState.insert(_moreMenuOverlay!);
  }

  Widget _buildMoreMenuPanel(ValueChanged<String?> setSubmenu) {
    return Container(
      width: 274,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMoreMenuRow(
            value: 'sort',
            label: 'Sort by',
            icon: Icons.swap_vert,
            trailing: Icons.chevron_right,
            onHover: () => setSubmenu('sort'),
            onTap: () => setSubmenu('sort'),
          ),
          _buildMoreMenuRow(
            value: 'import',
            label: 'Import Recurring Expenses',
            icon: Icons.file_download_outlined,
            onHover: () => setSubmenu(null),
            onTap: () => _logAndCloseMoreMenu('import'),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          _buildMoreMenuRow(
            value: 'export',
            label: 'Export',
            icon: Icons.file_upload_outlined,
            trailing: Icons.chevron_right,
            onHover: () => setSubmenu('export'),
            onTap: () => setSubmenu('export'),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          _buildMoreMenuRow(
            value: 'refresh',
            label: 'Refresh List',
            icon: Icons.refresh,
            onHover: () => setSubmenu(null),
            onTap: () => _logAndCloseMoreMenu('refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSubmenu({
    required double width,
    required List<String> values,
    required String activeValue,
    required ValueChanged<String> onItemTap,
    IconData? trailingIcon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            _buildMoreSubmenuRow(
              label: value,
              active: value == activeValue,
              trailingIcon: trailingIcon,
              onTap: () => onItemTap(value),
            ),
        ],
      ),
    );
  }

  Widget _buildMoreMenuRow({
    required String value,
    required String label,
    required IconData icon,
    required VoidCallback onHover,
    required VoidCallback onTap,
    IconData? trailing,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _moreMenuHoveredNotifier,
      builder: (context, hoveredValue, child) {
        final hovered = hoveredValue == value;
        final selected = _activeMoreSubmenu == value;
        final foreground = hovered
            ? AppTheme.backgroundColor
            : AppTheme.textBody;
        final iconColor = hovered
            ? AppTheme.backgroundColor
            : AppTheme.primaryBlueDark;
        final background = hovered
            ? AppTheme.infoBlue
            : selected
            ? AppTheme.selectionInactiveBg
            : Colors.transparent;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            _moreMenuHoveredNotifier.value = value;
            onHover();
          },
          onExit: (_) {
            if (_moreMenuHoveredNotifier.value == value) {
              _moreMenuHoveredNotifier.value = null;
            }
          },
          child: InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            child: Container(
              height: 46,
              constraints: const BoxConstraints(minWidth: 0),
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: hovered ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Icon(trailing, size: 20, color: iconColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreSubmenuRow({
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData? trailingIcon,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: _moreSubmenuHoveredNotifier,
      builder: (context, hoveredLabel, child) {
        final hovered = hoveredLabel == label;
        final hasHover = hoveredLabel != null;
        final highlighted = hovered || (active && !hasHover);
        final mutedSelected = active && hasHover && !hovered;
        final showTrailingIcon = trailingIcon != null && (active || hovered);
        final foreground = highlighted
            ? AppTheme.backgroundColor
            : AppTheme.textBody;
        final iconColor = highlighted
            ? AppTheme.backgroundColor
            : AppTheme.primaryBlueDark;
        final background = highlighted
            ? AppTheme.infoBlue
            : mutedSelected
            ? AppTheme.selectionInactiveBg
            : Colors.transparent;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _moreSubmenuHoveredNotifier.value = label,
          onExit: (_) {
            if (_moreSubmenuHoveredNotifier.value == label) {
              _moreSubmenuHoveredNotifier.value = null;
            }
          },
          child: InkWell(
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            child: Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.body.copyWith(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: highlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (showTrailingIcon)
                    Icon(trailingIcon, size: 18, color: iconColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _logAndCloseMoreMenu(String action) {
    AppLogger.info(
      'Selected recurring expenses more menu action',
      data: {'action': action},
      module: 'purchases_recurring_expenses',
    );
    _closeMoreMenuOverlay();
  }

  void _removeMoreMenuOverlay() {
    _moreMenuOverlay?.remove();
    _moreMenuOverlay = null;
  }

  void _closeMoreMenuOverlay() {
    _removeMoreMenuOverlay();
    _activeMoreSubmenu = null;
    _moreMenuHoveredNotifier.value = null;
  }

  Widget _buildRightPaneMoreMenu(
    BuildContext context,
    RecurringExpenseProfile profile,
  ) {
    final canStart = profile.status == RecurringExpenseStatus.stopped;
    final primaryActionValue = canStart ? 'start' : 'stop';
    final primaryActionLabel = canStart ? 'Start' : 'Stop';

    return PopupMenuButton<String>(
      enabled: !_isDetailActionLoading,
      offset: const Offset(0, 32),
      tooltip: '',
      elevation: 4,
      shadowColor: AppTheme.textPrimary.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      color: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onSelected: (String val) {
        AppLogger.info(
          'Selected recurring expense detail more action',
          data: {'action': val, 'profileId': profile.id},
          module: 'purchases_recurring_expenses',
        );
        _handleDetailAction(val, profile);
      },
      itemBuilder: (context) {
        _rightPaneMoreMenuHoveredNotifier.value = null;
        return [
          PopupMenuItem<String>(
            padding: EdgeInsets.zero,
            value: primaryActionValue,
            height: 42,
            child: RecurringExpenseHoverPopupMenuItem(
              label: primaryActionLabel,
              value: primaryActionValue,
              hoveredNotifier: _rightPaneMoreMenuHoveredNotifier,
              onTap: () => Navigator.of(context).pop(primaryActionValue),
            ),
          ),
          if (profile.status == RecurringExpenseStatus.active)
            PopupMenuItem<String>(
              padding: EdgeInsets.zero,
              value: 'create_expense',
              height: 42,
              child: RecurringExpenseHoverPopupMenuItem(
                label: 'Create Expense',
                value: 'create_expense',
                hoveredNotifier: _rightPaneMoreMenuHoveredNotifier,
                onTap: () => Navigator.of(context).pop('create_expense'),
              ),
            ),
          PopupMenuItem<String>(
            padding: EdgeInsets.zero,
            value: 'delete',
            height: 42,
            child: RecurringExpenseHoverPopupMenuItem(
              label: 'Delete',
              value: 'delete',
              hoveredNotifier: _rightPaneMoreMenuHoveredNotifier,
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ),
        ];
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('More', style: AppTextStyles.body),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoadingPage() {
    return ZerpaiLayout(
      pageTitle: '',
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: const ZListSkeleton(itemCount: 7),
      ),
    );
  }

  Widget _buildRecurringDetailsLoading() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ZBone(width: 220, height: 28),
            SizedBox(height: AppTheme.space12),
            ZBone(width: 120, height: 18),
            SizedBox(height: AppTheme.space24),
            ZTableSkeleton(rows: 4, columns: 4),
            SizedBox(height: AppTheme.space24),
            ZFormSkeleton(rows: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringGridLoading() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.space16),
      child: ZTableSkeleton(rows: 8, columns: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final selectedProfileId = state.uri.queryParameters['id'];
    final filterQuery = state.uri.queryParameters['filter'];
    final sortFieldQuery = state.uri.queryParameters['sortField'];
    final sortDirectionQuery = state.uri.queryParameters['sortDirection'];
    if (filterQuery != null) {
      final matchedOption = _recurringExpenseFilterOptions.firstWhere(
        (opt) => opt.value == filterQuery,
        orElse: () => _recurringExpenseFilterOptions.first,
      );
      if (_activeOption != matchedOption) {
        _activeOption = matchedOption;
      }
    } else {
      if (_activeOption != _recurringExpenseFilterOptions.first) {
        _activeOption = _recurringExpenseFilterOptions.first;
      }
    }
    _sortFieldLabel = _sortFieldLabelFromQueryValue(sortFieldQuery);
    _sortAscending = sortDirectionQuery?.toLowerCase() != 'desc';

    final orgSystemId = RecurringExpenseModuleDefaults.orgSystemId;
    final request = _listRequest();
    final recurringExpensesAsync = ref.watch(
      recurringExpensesProvider(request),
    );
    _hydrateProfilesFromCurrentResponse(recurringExpensesAsync);
    ref.listen<AsyncValue<RecurringExpenseResponse>>(
      recurringExpensesProvider(request),
      (
        AsyncValue<RecurringExpenseResponse>? previous,
        AsyncValue<RecurringExpenseResponse> next,
      ) {
        next.whenData((RecurringExpenseResponse response) {
          _syncProfilesFromBackend(response.items);
        });
      },
    );
    final RecurringExpenseResponse? currentResponse =
        recurringExpensesAsync.asData?.value;
    if (currentResponse != null) {
      _lastKnownTotalCount = currentResponse.total;
      _lastKnownTotalPages = currentResponse.totalPages;
    }
    final List<RecurringExpenseProfile> sourceProfiles =
        currentResponse?.items
            .map((RecurringExpense item) => item.copyWith())
            .toList() ??
        (_profiles.isNotEmpty ? _profiles : const <RecurringExpenseProfile>[]);
    final int totalCount =
        currentResponse?.total ?? _lastKnownTotalCount ?? sourceProfiles.length;
    final int totalPages =
        currentResponse?.totalPages ?? _lastKnownTotalPages ?? 1;
    final filteredExpenses = sourceProfiles;

    // Check if there is an active selection profile
    final RecurringExpenseProfile? selectedProfile =
        selectedProfileId != null && sourceProfiles.isNotEmpty
        ? sourceProfiles.firstWhere(
            (RecurringExpenseProfile p) => p.id == selectedProfileId,
            orElse: () => sourceProfiles.first,
          )
        : null;

    if (recurringExpensesAsync.isLoading && _profiles.isEmpty) {
      return _buildInitialLoadingPage();
    }

    final bool showPaginationFooter = totalCount > 10;

    if (selectedProfile != null) {
      final detailAsync = ref.watch(
        recurringExpenseDetailsProvider(selectedProfile.id),
      );
      // MASTER-DETAIL SPLIT-VIEW LAYOUT
      return ZerpaiLayout(
        pageTitle: '',
        actions: const [],
        enableBodyScroll: false,
        useHorizontalPadding: false,
        useTopPadding: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Pane: Profiles Card List (width 320 px)
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Pane Header
                  if (_selectedProfileIds.isNotEmpty)
                    RecurringExpenseOverviewSelectionRibbon(
                      selectedCount: _selectedProfileIds.length,
                      onAction: _onSelectionAction,
                      onClearSelection: _clearSelection,
                    )
                  else
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundColor,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildViewSelector(
                                context,
                                isDetailsMode: true,
                              ),
                            ),
                          ),
                          // Plus Button (+)
                          InkWell(
                            onTap: _onNewPressed,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.successDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  color: AppTheme.backgroundColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // More Options Button (...)
                          _buildMoreMenu(context, isCompact: true),
                        ],
                      ),
                    ),
                  // Cards list (scrollable)
                  Expanded(
                    child: Container(
                      color: AppTheme.backgroundColor,
                      child: ListView.builder(
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final profile = filteredExpenses[index];
                          final isCardSelected =
                              profile.id == selectedProfile.id;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  context.go(
                                    '/$orgSystemId${RecurringExpenseRoutes.list}?id=${Uri.encodeComponent(profile.id)}',
                                  );
                                },
                                child: Container(
                                  color: isCardSelected
                                      ? AppTheme.selectionActiveBg
                                      : AppTheme.backgroundColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _selectedProfileIds.contains(
                                            profile.id,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val ?? false) {
                                                _selectedProfileIds.add(
                                                  profile.id,
                                                );
                                              } else {
                                                _selectedProfileIds.remove(
                                                  profile.id,
                                                );
                                              }
                                              _allSelected =
                                                  _selectedProfileIds.length ==
                                                  _profiles.length;
                                            });
                                          },
                                          activeColor: AppTheme.primaryBlueDark,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    profile.name,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          color: AppTheme
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _formatCurrency(
                                                    profile.amount,
                                                  ),
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                        color: AppTheme
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    profile.expenseAccount,
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  profile.frequency,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  profile.statusText,
                                                  style: AppTextStyles.helper
                                                      .copyWith(
                                                        color: _statusColor(
                                                          profile.status,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  'Next expense date ${profile.nextExpenseDate}',
                                                  style: AppTextStyles.helper
                                                      .copyWith(
                                                        color: AppTheme
                                                            .textSecondary,
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
                              const Divider(
                                color: AppTheme.borderLight,
                                height: 1,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (showPaginationFooter)
                    _buildCompactPaginationFooter(
                      totalCount: totalCount,
                      page: _currentPage,
                      pageSize: _pageSize,
                      currentPageCount: filteredExpenses.length,
                    ),
                ],
              ),
            ),
            // Divider Line
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.borderLight,
            ),
            // Right Pane: Details Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Right Pane Top Header Action Bar
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Profile Title
                        Text(
                          selectedProfile.name,
                          style: AppTextStyles.title.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge (Stopped - Orange fill)
                        Container(
                          decoration: BoxDecoration(
                            color: _statusColor(selectedProfile.status),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            _detailStatusLabel(selectedProfile.status),
                            style: AppTextStyles.helper.copyWith(
                              color: AppTheme.backgroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Action Pencil Button (Edit)
                        InkWell(
                          onTap: () => _onEditPressed(selectedProfile),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit_outlined,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // More dropdown
                        _buildRightPaneMoreMenu(context, selectedProfile),
                        const SizedBox(width: 8),
                        // Close Action button (X)
                        InkWell(
                          onTap: () {
                            context.go(
                              '/$orgSystemId${RecurringExpenseRoutes.list}',
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab content widget
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final detailsPaneWidth = constraints.maxWidth;
                        return _isDetailActionLoading
                            ? _buildRecurringDetailsLoading()
                            : detailAsync.when(
                                data: (details) {
                                  if (details == null) {
                                    return Center(
                                      child: Text(
                                        'Recurring expense details are unavailable.',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  _scheduleDetailSync(details);
                                  final historyAsync = ref.watch(
                                    recurringExpenseHistoryProvider(
                                      selectedProfile.id,
                                    ),
                                  );
                                  final runsAsync = ref.watch(
                                    recurringExpenseRunsProvider(
                                      selectedProfile.id,
                                    ),
                                  );
                                  return historyAsync.when(
                                    data: (history) => runsAsync.when(
                                      data: (runs) => RecurringExpenseDetailsWidget(
                                        details: details,
                                        history: history,
                                        runs: runs,
                                        availableWidth: detailsPaneWidth,
                                        onClose: () {
                                          context.go(
                                            '/$orgSystemId${RecurringExpenseRoutes.list}',
                                          );
                                        },
                                      ),
                                      loading: _buildRecurringDetailsLoading,
                                      error: (_, __) =>
                                          RecurringExpenseDetailsWidget(
                                            details: details,
                                            history: history,
                                            runs: const <RecurringExpenseRun>[],
                                            availableWidth: detailsPaneWidth,
                                            onClose: () {
                                              context.go(
                                                '/$orgSystemId${RecurringExpenseRoutes.list}',
                                              );
                                            },
                                          ),
                                    ),
                                    loading: _buildRecurringDetailsLoading,
                                    error: (_, __) => runsAsync.when(
                                      data: (runs) => RecurringExpenseDetailsWidget(
                                        details: details,
                                        history:
                                            const <
                                              RecurringExpenseAuditHistoryEntry
                                            >[],
                                        runs: runs,
                                        availableWidth: detailsPaneWidth,
                                        onClose: () {
                                          context.go(
                                            '/$orgSystemId${RecurringExpenseRoutes.list}',
                                          );
                                        },
                                      ),
                                      loading: _buildRecurringDetailsLoading,
                                      error: (_, __) => RecurringExpenseDetailsWidget(
                                        details: details,
                                        history:
                                            const <
                                              RecurringExpenseAuditHistoryEntry
                                            >[],
                                        runs: const <RecurringExpenseRun>[],
                                        availableWidth: detailsPaneWidth,
                                        onClose: () {
                                          context.go(
                                            '/$orgSystemId${RecurringExpenseRoutes.list}',
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                loading: _buildRecurringDetailsLoading,
                                error: (error, _) => Center(
                                  child: Text(
                                    ErrorHandler.getFriendlyMessage(error),
                                    style: AppTextStyles.body.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // STANDARD FULL GRID VIEW
    final hasSelection = _selectedProfileIds.isNotEmpty;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasSelection)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                  child: RecurringExpenseSelectionRibbon(
                    selectedCount: _selectedProfileIds.length,
                    onAction: _onSelectionAction,
                    onClearSelection: _clearSelection,
                  ),
                )
              else
                _buildMainToolbar(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_isBulkStatusActionLoading)
                        Expanded(child: _buildRecurringGridLoading())
                      else
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              final columnWidths = _calculateColumnWidths(
                                tableConstraints.maxWidth,
                              );
                              final tableWidth = math.max(
                                tableConstraints.maxWidth,
                                _tableWidthFor(columnWidths),
                              );
                              return ResponsiveTableShell(
                                minWidth: tableWidth,
                                child: SizedBox(
                                  width: tableWidth,
                                  height: tableConstraints.maxHeight,
                                  child: filteredExpenses.isEmpty
                                      ? _buildEmptyTableStructure(
                                          filteredExpenses,
                                          columnWidths,
                                        )
                                      : _buildWrappedTable(
                                          orgSystemId,
                                          filteredExpenses,
                                          columnWidths,
                                          tableWidth,
                                          tableConstraints.maxHeight,
                                          showPaginationFooter
                                              ? _buildPaginationFooter(
                                                  totalCount: totalCount,
                                                  page: _currentPage,
                                                  pageSize: _pageSize,
                                                  totalPages: totalPages,
                                                  currentPageCount:
                                                      filteredExpenses.length,
                                                )
                                              : null,
                                        ),
                                ),
                              );
                            },
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
    );
  }
}
