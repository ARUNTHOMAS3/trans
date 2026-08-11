import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/sales/quotations/presentation/providers/sales_quotes_refresh_provider.dart';

class MockQuote {
  final String id;
  final String date;
  final DateTime? createdAt;
  final String location;
  final String paymentNumber;
  final String referenceNumber;
  final String vendorName;
  final String billNumber;
  final String mode;
  final String status;
  final double subTotal;
  final double amount;
  final double unusedAmount;
  final int attachmentCount;
  final String notes;
  final String paidThrough;
  final String depositToAccountId;
  final String acceptedDate;
  final String declinedDate;

  MockQuote({
    required this.id,
    required this.date,
    this.createdAt,
    required this.location,
    required this.paymentNumber,
    required this.referenceNumber,
    required this.vendorName,
    required this.billNumber,
    required this.mode,
    required this.status,
    required this.subTotal,
    required this.amount,
    required this.unusedAmount,
    this.attachmentCount = 0,
    this.notes = '',
    this.paidThrough = '',
    this.depositToAccountId = '',
    this.acceptedDate = '',
    this.declinedDate = '',
  });
}

// class _ReportAppliedBillRow {
//   final String billNumber;
//   final String billDate;
//   final double billAmount;
//   final double paymentAmount;
//
//   const _ReportAppliedBillRow({
//     required this.billNumber,
//     required this.billDate,
//     required this.billAmount,
//     required this.paymentAmount,
//   });
// }

class SalesQuotationReportPage extends ConsumerStatefulWidget {
  const SalesQuotationReportPage({super.key});

  @override
  ConsumerState<SalesQuotationReportPage> createState() =>
      _SalesQuotationReportPageState();
}

class _SalesQuotationReportPageState
    extends ConsumerState<SalesQuotationReportPage> {
  static const String _reportColumnsStorageKey =
      'sales_quotes_report_columns_v1';

  final List<MockQuote> _allQuotes = <MockQuote>[];

  // Selection state
  final Set<String> _selectedIds = {};

  // Columns configuration
  late List<ColumnConfig> _columns;

  // View/Filter menu state
  final MenuController _viewMenuController = MenuController();
  String _selectedView = 'All Quotes';
  bool _viewIsStarred = false;

  // Column Widths
  late Map<String, double> _colWidths;

  bool _isLoading = false;
  ProviderSubscription<int>? _refreshTickSubscription;

  Future<void> _deleteQuoteRowsByDbIds(List<String> quoteDbIds) async {
    if (quoteDbIds.isEmpty) return;
    final supabase = Supabase.instance.client;
    await supabase
        .from('sales_quotation_attachments')
        .delete()
        .inFilter('quotation_id', quoteDbIds);
    await supabase
        .from('sales_quotation_activity')
        .delete()
        .inFilter('quotation_id', quoteDbIds);
    await supabase
        .from('sales_quotation_items')
        .delete()
        .inFilter('quotation_id', quoteDbIds);
    await supabase.from('sales_quotations').delete().inFilter('id', quoteDbIds);
  }

  List<ColumnConfig> _buildDefaultColumns() {
    return [
      ColumnConfig(
        id: 'date',
        label: 'Date',
        isVisible: true,
        orderIndex: 0,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'location',
        label: 'Location',
        isVisible: true,
        orderIndex: 1,
      ),
      ColumnConfig(
        id: 'payment_no',
        label: 'Quote Number',
        isVisible: true,
        orderIndex: 2,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'reference',
        label: 'Reference#',
        isVisible: true,
        orderIndex: 3,
      ),
      ColumnConfig(
        id: 'vendor_name',
        label: 'Customer Name',
        isVisible: true,
        orderIndex: 4,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'status',
        label: 'Quote Status',
        isVisible: true,
        orderIndex: 5,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'amount',
        label: 'Total',
        isVisible: true,
        orderIndex: 6,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'accepted_date',
        label: 'Accepted Date',
        isVisible: true,
        orderIndex: 7,
      ),
      ColumnConfig(
        id: 'company_name',
        label: 'Company Name',
        isVisible: true,
        orderIndex: 8,
      ),
      ColumnConfig(
        id: 'declined_date',
        label: 'Declined Date',
        isVisible: false,
        orderIndex: 10,
      ),
      ColumnConfig(
        id: 'bill_no',
        label: 'Expiry Date',
        isVisible: false,
        orderIndex: 11,
      ),
      ColumnConfig(
        id: 'mode',
        label: 'Salesperson',
        isVisible: false,
        orderIndex: 12,
      ),
      ColumnConfig(
        id: 'sub_total',
        label: 'Sub Total',
        isVisible: false,
        orderIndex: 13,
      ),
    ];
  }

  List<ColumnConfig> _mergeStoredColumns(List<dynamic> rawColumns) {
    final defaults = _buildDefaultColumns();
    final defaultById = {
      for (final column in defaults)
        column.id: ColumnConfig(
          id: column.id,
          label: column.label,
          isVisible: column.isVisible,
          orderIndex: column.orderIndex,
          isLocked: column.isLocked,
          isPinned: column.isPinned,
        ),
    };

    final storedColumns = rawColumns
        .whereType<Map>()
        .map(
          (raw) => ColumnConfig.fromJson(
            Map<String, dynamic>.from(raw.cast<dynamic, dynamic>()),
          ),
        )
        .toList();

    for (final stored in storedColumns) {
      final target = defaultById[stored.id];
      if (target == null) continue;
      target.isVisible = stored.isVisible;
      target.orderIndex = stored.orderIndex;
      target.isLocked = stored.isLocked;
      target.isPinned = stored.isPinned;
    }

    final merged = defaultById.values.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (var i = 0; i < merged.length; i++) {
      merged[i].orderIndex = i;
    }
    return merged;
  }

  Future<void> _restoreSavedColumns() async {
    try {
      final box = Hive.box('config');
      final rawColumns = box.get(_reportColumnsStorageKey);
      if (rawColumns is! List) return;

      final restoredColumns = _mergeStoredColumns(rawColumns);
      if (!mounted) return;
      setState(() {
        _columns = restoredColumns;
      });
    } catch (_) {
      // Keep default columns if local UI preferences are unavailable.
    }
  }

  Future<void> _persistColumns() async {
    try {
      final box = Hive.box('config');
      await box.put(
        _reportColumnsStorageKey,
        _columns.map((column) => column.toJson()).toList(),
      );
    } catch (_) {
      // Skip persistence failures without blocking report usage.
    }
  }

  String? _toIsoDateString(String value) {
    final parsed = DateFormat('dd-MM-yyyy').parseStrict(value);
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Map<String, dynamic> _buildBulkUpdatePayload(String field, dynamic value) {
    switch (field) {
      case 'Quote Date':
        if (value is String && value.trim().isNotEmpty) {
          return {'sale_date': _toIsoDateString(value.trim())};
        }
        break;
      case 'Location':
        if (value is String) {
          return {'place_of_supply': value.trim()};
        }
        break;
      case 'Salesperson':
        if (value is String) {
          return {'salesperson': value.trim()};
        }
        break;
      case 'Status':
        if (value is String) {
          return {'status': value.trim()};
        }
        break;
      case 'Reference#':
        if (value is String) {
          return {'reference': value.trim()};
        }
        break;
      case 'Notes':
        if (value is String) {
          return {'customer_notes': value};
        }
        break;
      case 'Quote Terms':
        if (value is String) {
          return {'payment_terms': value.trim()};
        }
        break;
      case 'Price List':
        if (value is String) {
          return {'price_list_id': value.trim()};
        }
        break;
    }
    return const {};
  }

  Future<void> _applyBulkUpdateToDb(
    Set<String> selectedPaymentNumbers,
    String field,
    dynamic value,
  ) async {
    final payload = _buildBulkUpdatePayload(field, value);
    if (payload.isEmpty) return;

    final supabase = Supabase.instance.client;
    final selectedRows = _allQuotes
        .where((p) => selectedPaymentNumbers.contains(p.paymentNumber))
        .toList();

    await Future.wait(
      selectedRows
          .where((p) => p.id.isNotEmpty)
          .map(
            (payment) => supabase
                .from('sales_quotations')
                .update(payload)
                .eq('id', payment.id),
          ),
    );
  }

  void _applyBulkUpdateLocally(
    Set<String> selectedPaymentNumbers,
    String field,
    dynamic value,
  ) {
    String normalizeDate(dynamic raw) {
      if (raw is! String || raw.trim().isEmpty) return '';
      final parsed = DateFormat('dd-MM-yyyy').parseStrict(raw.trim());
      return DateFormat('dd-MM-yyyy').format(parsed);
    }

    setState(() {
      for (var i = 0; i < _allQuotes.length; i++) {
        final payment = _allQuotes[i];
        if (!selectedPaymentNumbers.contains(payment.paymentNumber)) {
          continue;
        }

        _allQuotes[i] = MockQuote(
          id: payment.id,
          date: field == 'Quote Date' ? normalizeDate(value) : payment.date,
          location: payment.location,
          paymentNumber: payment.paymentNumber,
          referenceNumber: field == 'Reference#'
              ? (value?.toString() ?? '')
              : payment.referenceNumber,
          vendorName: payment.vendorName,
          billNumber: payment.billNumber,
          mode: field == 'Salesperson'
              ? (value?.toString() ?? '')
              : payment.mode,
          status: payment.status,
          subTotal: payment.subTotal,
          amount: payment.amount,
          unusedAmount: payment.unusedAmount,
          attachmentCount: payment.attachmentCount,
          notes: field == 'Notes' ? (value?.toString() ?? '') : payment.notes,
          paidThrough: field == 'Quote Terms'
              ? (value?.toString() ?? '')
              : payment.paidThrough,
          depositToAccountId: field == 'Price List'
              ? (value?.toString() ?? '')
              : payment.depositToAccountId,
          acceptedDate: payment.acceptedDate,
          declinedDate: payment.declinedDate,
        );
      }
    });
  }

  Future<void> _loadPaymentsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      List<dynamic> response;
      try {
        response = await supabase
            .from('sales_quotations')
            .select(
              'id, quotation_number, quotation_date, place_of_supply, '
              'reference_number, status, subtotal, grand_total, tax_total, '
              'customer_notes, '
              'price_list_id, salesperson_id, created_at, '
              'customer:customers(display_name)',
            )
            .order('created_at', ascending: false);
      } catch (_) {
        response = await supabase
            .from('sales_quotations')
            .select(
              'id, quotation_number, quotation_date, place_of_supply, '
              'reference_number, status, sub_total, grand_total, tax_total, '
              'customer_notes, '
              'price_list_id, salesperson_id, created_at, '
              'customer:customers(display_name)',
            )
            .order('created_at', ascending: false);
      }
      final rows = response.cast<Map<String, dynamic>>();

      final salespersonIds = rows
          .map((row) => row['salesperson_id']?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final Map<String, String> salespersonNamesById = <String, String>{};
      if (salespersonIds.isNotEmpty) {
        final usersResponse = await supabase
            .from('users')
            .select('id, full_name, email')
            .inFilter('id', salespersonIds);
        for (final user in usersResponse as List<dynamic>) {
          final userMap = Map<String, dynamic>.from(user as Map);
          final id = userMap['id']?.toString().trim() ?? '';
          final fullName = userMap['full_name']?.toString().trim() ?? '';
          final email = userMap['email']?.toString().trim() ?? '';
          if (id.isNotEmpty) {
            salespersonNamesById[id] = fullName.isNotEmpty
                ? fullName
                : (email.isNotEmpty ? email.split('@').first : id);
          }
        }
      }

      final quotationIds = rows
          .map((row) => row['id']?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final Map<String, int> attachmentCountByQuotationId = <String, int>{};
      final Map<String, String> acceptedDateByQuotationId = <String, String>{};
      final Map<String, String> declinedDateByQuotationId = <String, String>{};
      if (quotationIds.isNotEmpty) {
        final attachmentsResponse = await supabase
            .from('sales_quotation_attachments')
            .select('quotation_id')
            .inFilter('quotation_id', quotationIds);
        for (final attachment in attachmentsResponse as List<dynamic>) {
          final attachmentRow = Map<String, dynamic>.from(attachment as Map);
          final quotationId =
              attachmentRow['quotation_id']?.toString().trim() ?? '';
          if (quotationId.isEmpty) continue;
          attachmentCountByQuotationId[quotationId] =
              (attachmentCountByQuotationId[quotationId] ?? 0) + 1;
        }

        final activitiesResponse = await supabase
            .from('sales_quotation_activity')
            .select('quotation_id, action, created_at')
            .inFilter('quotation_id', quotationIds)
            .order('created_at', ascending: false);
        for (final activity in activitiesResponse as List<dynamic>) {
          final activityRow = Map<String, dynamic>.from(activity as Map);
          final quotationId =
              activityRow['quotation_id']?.toString().trim() ?? '';
          final action =
              activityRow['action']?.toString().trim().toLowerCase() ?? '';
          final createdAt = DateTime.tryParse(
            activityRow['created_at']?.toString() ?? '',
          );
          if (quotationId.isEmpty || createdAt == null) {
            continue;
          }
          final formattedDate = DateFormat('dd-MM-yyyy').format(createdAt);
          if ((action == 'marked_as_accepted' || action == 'accepted') &&
              !acceptedDateByQuotationId.containsKey(quotationId)) {
            acceptedDateByQuotationId[quotationId] = formattedDate;
          }
          if ((action == 'marked_as_declined' || action == 'declined') &&
              !declinedDateByQuotationId.containsKey(quotationId)) {
            declinedDateByQuotationId[quotationId] = formattedDate;
          }
        }
      }

      final List<MockQuote> loaded = [];
      for (final p in rows) {
        final customer = p['customer'];
        final customerName = customer is Map<String, dynamic>
            ? (customer['display_name']?.toString().trim() ?? '')
            : '';
        final salespersonId = p['salesperson_id']?.toString().trim() ?? '';
        final salespersonName = salespersonNamesById[salespersonId];
        loaded.add(
          MockQuote(
            id: p['id']?.toString() ?? '',
            date: p['quotation_date'] != null
                ? DateFormat('dd-MM-yyyy').format(
                    DateTime.tryParse(p['quotation_date'].toString()) ??
                        DateTime.now(),
                  )
                : '',
            createdAt: DateTime.tryParse(p['created_at']?.toString() ?? ''),
            location:
                (p['place_of_supply']?.toString().trim().isNotEmpty ?? false)
                ? p['place_of_supply'].toString().trim()
                : '-',
            paymentNumber: p['quotation_number']?.toString() ?? '',
            referenceNumber: p['reference_number']?.toString() ?? '',
            vendorName: customerName.isNotEmpty ? customerName : '-',
            billNumber: '',
            mode: salespersonName != null && salespersonName.isNotEmpty
                ? salespersonName
                : (salespersonId.isNotEmpty ? salespersonId : '-'),
            status: p['status']?.toString() ?? 'draft',
            subTotal:
                (p['subtotal'] as num?)?.toDouble() ??
                (p['sub_total'] as num?)?.toDouble() ??
                0.0,
            amount: (p['grand_total'] as num?)?.toDouble() ?? 0.0,
            unusedAmount: (p['tax_total'] as num?)?.toDouble() ?? 0.0,
            attachmentCount:
                attachmentCountByQuotationId[p['id']?.toString() ?? ''] ?? 0,
            notes: p['customer_notes']?.toString() ?? '',
            paidThrough: '',
            depositToAccountId: p['price_list_id']?.toString() ?? '',
            acceptedDate:
                acceptedDateByQuotationId[p['id']?.toString() ?? ''] ?? '',
            declinedDate:
                declinedDateByQuotationId[p['id']?.toString() ?? ''] ?? '',
          ),
        );
      }

      setState(() {
        _allQuotes
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allQuotes.clear();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load quotes: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentsFromDb();
    _refreshTickSubscription = ref.listenManual<int>(
      salesQuotationRefreshTickProvider,
      (previous, next) {
        if (previous != next && mounted) {
          _loadPaymentsFromDb();
        }
      },
    );
    _colWidths = {
      'checkbox': 80,
      'date': 110,
      'location': 180,
      'payment_no': 130,
      'reference': 150,
      'vendor_name': 280,
      'accepted_date': 130,
      'crm_potential_name': 170,
      'company_name': 180,
      'declined_date': 130,
      'bill_no': 100,
      'mode': 130,
      'sub_total': 130,
      'status': 90,
      'amount': 130,
      'unused': 130,
      'actions': 50,
    };
    _columns = _buildDefaultColumns();
    Future.microtask(_restoreSavedColumns);
  }

  // Sort state
  bool _sortAscending =
      false; // Descending by default as in screenshot (newest dates first)
  String _sortByField = 'date';
  bool _wrapText = false;

  // Search state
  bool _showSearchRow = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Scroll controllers
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // Hover states
  String? _hoveredRowId;

  // Formatting helpers
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _refreshTickSubscription?.close();
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Parse dates for sorting
  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateStr);
    } catch (_) {
      return DateTime(1970);
    }
  }

  int _extractQuoteNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  List<MockQuote> _getFilteredAndSortedPayments() {
    // 1. Filter
    List<MockQuote> results = List.from(_allQuotes);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((p) {
        return p.vendorName.toLowerCase().contains(query) ||
            p.paymentNumber.toLowerCase().contains(query) ||
            p.billNumber.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Sort by selected field
    results.sort((a, b) {
      int comparison = 0;
      switch (_sortByField) {
        case 'date':
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          comparison = dateA.compareTo(dateB);
          break;
        case 'payment_no':
          final numA = _extractQuoteNumber(a.paymentNumber);
          final numB = _extractQuoteNumber(b.paymentNumber);
          comparison = numA.compareTo(numB);
          break;
        case 'reference':
          comparison = a.referenceNumber.compareTo(b.referenceNumber);
          break;
        case 'vendor_name':
          comparison = a.vendorName.toLowerCase().compareTo(
            b.vendorName.toLowerCase(),
          );
          break;
        case 'mode':
          comparison = a.mode.compareTo(b.mode);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'sub_total':
          comparison = a.subTotal.compareTo(b.subTotal);
          break;
        case 'unused':
          comparison = a.unusedAmount.compareTo(b.unusedAmount);
          break;
        case 'created_time':
          final createdA = a.createdAt ?? _parseDate(a.date);
          final createdB = b.createdAt ?? _parseDate(b.date);
          comparison = createdA.compareTo(createdB);
          break;
        default:
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          comparison = dateA.compareTo(dateB);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return results;
  }

  void _toggleSelectAll(bool? checked, List<MockQuote> visibleRows) {
    setState(() {
      if (checked == true) {
        for (final r in visibleRows) {
          _selectedIds.add(r.paymentNumber);
        }
      } else {
        for (final r in visibleRows) {
          _selectedIds.remove(r.paymentNumber);
        }
      }
    });
  }

  void _selectPayment(String paymentNumber) {
    context.go(
      AppRoutes.salesQuotationsDetail.replaceAll(':id', paymentNumber),
    );
  }

  void _deselectPayment() {
    context.go(AppRoutes.salesQuotations);
  }

  Widget _buildViewDropdownContent() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ViewOptionRow(
            label: 'All Quotes',
            isSelected: _selectedView == 'All Quotes',
            isStarred: _viewIsStarred,
            onTap: () {
              setState(() {
                _selectedView = 'All Quotes';
              });
              _viewMenuController.close();
            },
            onStarTap: () {
              setState(() {
                _viewIsStarred = !_viewIsStarred;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgId = resolveOrgSystemId(context);
    final state = GoRouterState.of(context);
    final selectedPaymentId = state.uri.queryParameters['quoteId'];

    // Find the currently selected payment object for the details overlay
    MockQuote? selectedPayment;
    if (selectedPaymentId != null) {
      try {
        selectedPayment = _allQuotes.firstWhere(
          (p) => p.paymentNumber == selectedPaymentId,
        );
      } catch (_) {}
    }

    final List<MockQuote> dummyList = List.generate(
      8,
      (index) => MockQuote(
        id: 'loading-$index',
        date: '',
        createdAt: null,
        location: '',
        paymentNumber: '',
        referenceNumber: '',
        vendorName: '',
        billNumber: '',
        mode: '',
        status: '',
        subTotal: 0.0,
        amount: 0.0,
        unusedAmount: 0.0,
        attachmentCount: 0,
        acceptedDate: '',
        declinedDate: '',
      ),
    );

    final visiblePayments = _isLoading && _allQuotes.isEmpty
        ? dummyList
        : _getFilteredAndSortedPayments();
    final allVisibleSelected =
        visiblePayments.isNotEmpty &&
        visiblePayments.every((p) => _selectedIds.contains(p.paymentNumber));

    final scaffoldBody = Skeletonizer(
      enabled: _isLoading,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, orgId),
              _buildSearchFilterToolbar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      controller: _verticalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        scrollDirection: Axis.vertical,
                        child: _buildTable(
                          visiblePayments,
                          allVisibleSelected,
                          constraints.maxWidth,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (selectedPayment != null) _buildDetailsOverlay(selectedPayment),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (_selectedIds.isNotEmpty)
            const SingleActivator(LogicalKeyboardKey.escape): () {
              setState(() {
                _selectedIds.clear();
              });
            },
        },
        child: Focus(autofocus: true, child: scaffoldBody),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String orgId) {
    if (_selectedIds.isNotEmpty) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => BulkUpdateDialog(
                    selectedPaymentNumbers: _selectedIds.toList(),
                  ),
                );
                if (result != null) {
                  final field = result['field'] as String;
                  final value = result['value'];
                  final selectedPaymentNumbers = Set<String>.from(_selectedIds);
                  setState(() => _isLoading = true);
                  try {
                    await _applyBulkUpdateToDb(
                      selectedPaymentNumbers,
                      field,
                      value,
                    );
                    _applyBulkUpdateLocally(
                      selectedPaymentNumbers,
                      field,
                      value,
                    );
                    if (!mounted) return;
                    setState(() {
                      _selectedIds.clear();
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quotes updated successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update quotes: $e')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderColor),
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Bulk Update',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final confirmed = await showZerpaiConfirmationDialog(
                  context,
                  title: 'Delete Quotes',
                  message:
                      'Are you sure you want to delete the selected quotes? This action cannot be undone.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  variant: ZerpaiConfirmationVariant.danger,
                );
                if (confirmed) {
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    final quoteDbIds = _allQuotes
                        .where((p) => _selectedIds.contains(p.paymentNumber))
                        .map((p) => p.id.trim())
                        .where((id) => id.isNotEmpty)
                        .toList();
                    await _deleteQuoteRowsByDbIds(quoteDbIds);
                    if (mounted) {
                      setState(() {
                        _allQuotes.removeWhere(
                          (p) => _selectedIds.contains(p.paymentNumber),
                        );
                        _selectedIds.clear();
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quotes deleted successfully.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete quotes: $e')),
                      );
                    }
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.borderColor),
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: AppTheme.borderColor),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedIds.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Selected',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedIds.clear();
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Esc',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close, color: AppTheme.errorRed, size: 16),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          MenuAnchor(
            controller: _viewMenuController,
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: const WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
            builder: (context, controller, child) {
              final isOpen = controller.isOpen;
              return InkWell(
                onTap: () => isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedView,
                        style: AppTheme.textPrimaryStyle(
                          18,
                          FontWeight.w600,
                        ).copyWith(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color: AppTheme.primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [_buildViewDropdownContent()],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              final state = GoRouterState.of(context);
              context.goNamed(
                AppRoutes.salesQuotationsCreate,
                pathParameters: state.pathParameters,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'New',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MenuAnchor(
            alignmentOffset: const Offset(-200, 4),
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(
                AppTheme.backgroundColor,
              ),
              surfaceTintColor: const WidgetStatePropertyAll(
                AppTheme.backgroundColor,
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
              elevation: const WidgetStatePropertyAll(8),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            builder: (context, controller, child) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(),
                ),
              );
            },
            menuChildren: [
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                alignmentOffset: const Offset(8, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  _buildSortMenuItem('Date', 'date'),
                  _buildSortMenuItem('Quote #', 'payment_no'),
                  _buildSortMenuItem('Reference#', 'reference'),
                  _buildSortMenuItem('Customer Name', 'vendor_name'),
                  _buildSortMenuItem('Salesperson', 'mode'),
                  _buildSortMenuItem('Amount', 'amount'),
                  _buildSortMenuItem('Tax Total', 'unused'),
                  _buildSortMenuItem('Created Time', 'created_time'),
                ],
                child: Row(
                  children: const [
                    Icon(LucideIcons.arrowUpDown, size: 14),
                    SizedBox(width: 12),
                    Text('Sort by', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                alignmentOffset: const Offset(8, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importing quotes...')),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Import Quotes',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Importing quote adjustments...'),
                        ),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Import Quote Data',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                child: Row(
                  children: const [
                    Icon(LucideIcons.download, size: 14),
                    SizedBox(width: 12),
                    Text('Import', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                alignmentOffset: const Offset(8, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting quotes...')),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Export Quotes',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                child: Row(
                  children: const [
                    Icon(LucideIcons.upload, size: 14),
                    SizedBox(width: 12),
                    Text('Export', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              MenuItemButton(
                onPressed: () {
                  setState(() {
                    _sortByField = 'date';
                    _sortAscending = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('List refreshed.')),
                  );
                },
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: Row(
                  children: const [
                    Icon(LucideIcons.refreshCw, size: 14),
                    SizedBox(width: 12),
                    Text('Refresh List', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String fieldId) {
    final bool isActive = _sortByField == fieldId;
    return MenuItemButton(
      onPressed: () {
        setState(() {
          if (_sortByField == fieldId) {
            _sortAscending = !_sortAscending;
          } else {
            _sortByField = fieldId;
            _sortAscending = fieldId == 'date' || fieldId == 'created_time'
                ? false
                : true;
          }
        });
      },
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isActive),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildSearchFilterToolbar() {
    if (!_showSearchRow && _searchQuery.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search by Customer, Quote #, Expiry Date...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTable(
    List<MockQuote> visiblePayments,
    bool allVisibleSelected,
    double minWidth,
  ) {
    // Columns config and widths
    final colWidths = _colWidths;

    final activeColumns = _columns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final frozenWidth = colWidths['checkbox']!;
    double totalWidth = colWidths['actions']!;
    for (final col in activeColumns) {
      totalWidth += colWidths[col.id] ?? 0;
    }
    final scrollableMinWidth = (minWidth - frozenWidth).clamp(
      0.0,
      double.infinity,
    );
    final scrollableWidth = totalWidth < scrollableMinWidth
        ? scrollableMinWidth
        : totalWidth;

    return Container(
      width: minWidth,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: frozenWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      ZTableHeaderMenu(
                        wrapText: _wrapText,
                        onWrapChange: (val) {
                          setState(() {
                            _wrapText = val;
                          });
                        },
                        onCustomize: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => ColumnCustomizerDialog(
                              columns: _columns,
                              onSave: (updatedColumns) async {
                                setState(() {
                                  _columns = updatedColumns;
                                });
                                await _persistColumns();
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: allVisibleSelected,
                              activeColor: AppTheme.primaryBlue,
                              side: const BorderSide(
                                color: Color(0xFF6B7280),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              onChanged: (v) =>
                                  _toggleSelectAll(v, visiblePayments),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (visiblePayments.isEmpty)
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(border: Border()),
                  )
                else
                  ...visiblePayments.map((p) {
                    final isChecked = _selectedIds.contains(p.paymentNumber);
                    final isHovered = _hoveredRowId == p.paymentNumber;
                    return MouseRegion(
                      onEnter: (_) =>
                          setState(() => _hoveredRowId = p.paymentNumber),
                      onExit: (_) => setState(() => _hoveredRowId = null),
                      child: Container(
                        height: _wrapText ? null : 56,
                        constraints: _wrapText
                            ? const BoxConstraints(minHeight: 56)
                            : null,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xFFF1F5F9)
                              : (isHovered
                                    ? const Color(0xFFF9FAFB)
                                    : Colors.white),
                          border: const Border(
                            bottom: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const SizedBox(width: 28),
                            const SizedBox(width: 7),
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: isChecked,
                                    activeColor: AppTheme.primaryBlue,
                                    side: const BorderSide(
                                      color: Color(0xFF6B7280),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedIds.add(p.paymentNumber);
                                        } else {
                                          _selectedIds.remove(p.paymentNumber);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: scrollableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            ...activeColumns.map((col) {
                              final isSortable =
                                  col.id == 'date' ||
                                  col.id == 'payment_no' ||
                                  col.id == 'reference' ||
                                  col.id == 'vendor_name' ||
                                  col.id == 'mode' ||
                                  col.id == 'amount' ||
                                  col.id == 'unused';
                              final isSorted = _sortByField == col.id;

                              return _buildHeaderCell(
                                colId: col.id,
                                label: col.label.toUpperCase(),
                                width: colWidths[col.id]!,
                                isSortable: isSortable,
                                isSorted: isSorted,
                                sortAscending: _sortAscending,
                                align:
                                    (col.id == 'amount' || col.id == 'unused')
                                    ? TextAlign.right
                                    : TextAlign.left,
                                onTap: isSortable
                                    ? () {
                                        setState(() {
                                          if (_sortByField == col.id) {
                                            _sortAscending = !_sortAscending;
                                          } else {
                                            _sortByField = col.id;
                                            _sortAscending = true;
                                          }
                                        });
                                      }
                                    : null,
                              );
                            }),
                            SizedBox(width: colWidths['actions']),
                          ],
                        ),
                      ),
                      if (visiblePayments.isEmpty)
                        Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'No quotes found matching criteria.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...visiblePayments.map((p) {
                          final isChecked = _selectedIds.contains(
                            p.paymentNumber,
                          );
                          final isHovered = _hoveredRowId == p.paymentNumber;
                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredRowId = p.paymentNumber),
                            onExit: (_) => setState(() => _hoveredRowId = null),
                            child: Container(
                              height: _wrapText ? null : 56,
                              constraints: _wrapText
                                  ? const BoxConstraints(minHeight: 56)
                                  : null,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? const Color(0xFFF1F5F9)
                                    : (isHovered
                                          ? const Color(0xFFF9FAFB)
                                          : Colors.white),
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _selectPayment(p.paymentNumber),
                                child: Row(
                                  children: [
                                    ...activeColumns.map((col) {
                                      if (col.id == 'date') {
                                        return _buildCell(
                                          text: p.date,
                                          width: colWidths['date']!,
                                        );
                                      }
                                      if (col.id == 'location') {
                                        return _buildCell(
                                          text: p.location,
                                          width: colWidths['location']!,
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF374151),
                                          ),
                                        );
                                      }
                                      if (col.id == 'payment_no') {
                                        return SizedBox(
                                          width: colWidths['payment_no']!,
                                          child: Align(
                                            alignment: _wrapText
                                                ? Alignment.topLeft
                                                : Alignment.centerLeft,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: _wrapText ? 12 : 0,
                                              ),
                                              child: InkWell(
                                                onTap: () => _selectPayment(
                                                  p.paymentNumber,
                                                ),
                                                child: Text(
                                                  p.paymentNumber,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.primaryBlue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  maxLines: _wrapText
                                                      ? null
                                                      : 1,
                                                  overflow: _wrapText
                                                      ? TextOverflow.clip
                                                      : TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      if (col.id == 'reference') {
                                        return _buildCell(
                                          text: p.referenceNumber,
                                          width: colWidths['reference']!,
                                        );
                                      }
                                      if (col.id == 'vendor_name') {
                                        return _buildCell(
                                          text: p.vendorName,
                                          width: colWidths['vendor_name']!,
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        );
                                      }
                                      if (col.id == 'bill_no') {
                                        return _buildCell(
                                          text: p.billNumber.isEmpty
                                              ? '-'
                                              : p.billNumber,
                                          width: colWidths['bill_no']!,
                                        );
                                      }
                                      if (col.id == 'mode') {
                                        return _buildCell(
                                          text: p.mode,
                                          width: colWidths['mode']!,
                                        );
                                      }
                                      if (col.id == 'status') {
                                        final st = p.status.toLowerCase();
                                        final statusColor = st == 'void'
                                            ? AppTheme.errorRed
                                            : st == 'draft'
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF10B981);
                                        return _buildCell(
                                          text: p.status.toUpperCase(),
                                          width: colWidths['status']!,
                                          textStyle: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        );
                                      }
                                      if (col.id == 'accepted_date') {
                                        return _buildCell(
                                          text: p.acceptedDate.isEmpty
                                              ? '-'
                                              : p.acceptedDate,
                                          width: colWidths['accepted_date']!,
                                        );
                                      }
                                      if (col.id == 'crm_potential_name') {
                                        return _buildCell(
                                          text: '-',
                                          width:
                                              colWidths['crm_potential_name']!,
                                        );
                                      }
                                      if (col.id == 'company_name') {
                                        return _buildCell(
                                          text: p.vendorName,
                                          width: colWidths['company_name']!,
                                        );
                                      }
                                      if (col.id == 'declined_date') {
                                        return _buildCell(
                                          text: p.declinedDate.isEmpty
                                              ? '-'
                                              : p.declinedDate,
                                          width: colWidths['declined_date']!,
                                        );
                                      }
                                      if (col.id == 'amount') {
                                        return _buildCell(
                                          text: _currencyFormat.format(
                                            p.amount,
                                          ),
                                          width: colWidths['amount']!,
                                          align: TextAlign.right,
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        );
                                      }
                                      if (col.id == 'sub_total') {
                                        return _buildCell(
                                          text: _currencyFormat.format(
                                            p.subTotal,
                                          ),
                                          width: colWidths['sub_total']!,
                                          align: TextAlign.left,
                                          forceTopAlignment: true,
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF374151),
                                          ),
                                        );
                                      }
                                      if (col.id == 'unused') {
                                        return _buildCell(
                                          text: _currencyFormat.format(
                                            p.unusedAmount,
                                          ),
                                          width: colWidths['unused']!,
                                          align: TextAlign.right,
                                          textStyle: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: p.unusedAmount > 0
                                                ? const Color(0xFF374151)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                    SizedBox(
                                      width: colWidths['actions']!,
                                      child: p.attachmentCount > 0
                                          ? Align(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                LucideIcons.paperclip,
                                                size: 16,
                                                color: const Color(0xFF111827),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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

  Widget _buildHeaderCell({
    required String colId,
    required String label,
    required double width,
    bool isSortable = false,
    bool isSorted = false,
    bool sortAscending = true,
    VoidCallback? onTap,
    TextAlign align = TextAlign.left,
  }) {
    final cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: align,
              overflow: _wrapText ? TextOverflow.clip : TextOverflow.ellipsis,
              maxLines: _wrapText ? null : 1,
              style: AppTheme.metaHelper.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (isSortable && isSorted) ...[
            const SizedBox(width: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.chevronUp,
                  size: 9,
                  color: sortAscending
                      ? const Color(0xFF111827)
                      : const Color(0xFFD1D5DB),
                ),
                const SizedBox(height: 1),
                Icon(
                  LucideIcons.chevronDown,
                  size: 9,
                  color: !sortAscending
                      ? const Color(0xFF111827)
                      : const Color(0xFFD1D5DB),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: isSortable && onTap != null
                ? InkWell(onTap: onTap, child: cell)
                : cell,
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 12,
            child: _ResizeHandle(
              onDrag: (dx) {
                setState(() {
                  final newWidth = (_colWidths[colId] ?? width) + dx;
                  _colWidths[colId] = newWidth.clamp(60.0, 600.0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required String text,
    required double width,
    TextAlign align = TextAlign.left,
    TextStyle? textStyle,
    bool forceTopAlignment = false,
  }) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: align == TextAlign.right
            ? ((_wrapText || forceTopAlignment)
                  ? Alignment.topRight
                  : Alignment.centerRight)
            : ((_wrapText || forceTopAlignment)
                  ? Alignment.topLeft
                  : Alignment.centerLeft),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: (_wrapText || forceTopAlignment) ? 12 : 0,
          ),
          child: Text(
            text,
            style: textStyle ?? AppTheme.tableCell.copyWith(fontSize: 13),
            maxLines: _wrapText ? null : 1,
            overflow: _wrapText ? TextOverflow.clip : TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsOverlay(MockQuote p) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 480,
      child: Material(
        elevation: 16,
        color: Colors.white,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header of details drawer
              _buildDetailsHeader(p),
              // Body content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status / Title card
                      _buildReceiptTitleCard(p),
                      const SizedBox(height: 24),
                      // Quote metadata block
                      _buildPaymentMetaBlock(p),
                      const SizedBox(height: 24),
                      // Amount Summary block
                      _buildAmountSummaryBlock(p),
                      const SizedBox(height: 24),
                      // Bills paid sub-table
                      _buildBillsPaidSection(p),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsHeader(MockQuote p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quote ${p.paymentNumber}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Neutral buttons matching global standards
          IconButton(
            icon: const Icon(
              LucideIcons.printer,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {},
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.download,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {},
            tooltip: 'Download PDF',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            onPressed: _deselectPayment,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTitleCard(MockQuote p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            color: Color(0xFF10B981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.vendorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quote prepared by ${p.mode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMetaBlock(MockQuote p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUOTE SUMMARY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _buildMetaRow('Quote Date', p.date),
              const Divider(height: 20, color: AppTheme.borderColor),
              _buildMetaRow('Location', p.location),
              const Divider(height: 20, color: AppTheme.borderColor),
              _buildMetaRow('Salesperson', p.mode),
              const Divider(height: 20, color: AppTheme.borderColor),
              _buildMetaRow(
                'Reference #',
                p.referenceNumber.isEmpty ? 'N/A' : p.referenceNumber,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSummaryBlock(MockQuote p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quote Amount',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                _currencyFormat.format(p.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tax Total',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                _currencyFormat.format(p.unusedAmount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.unusedAmount > 0
                      ? const Color(0xFFEA580C)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillsPaidSection(MockQuote p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quote Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F2A24),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF1F1F1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 18,
                      child: Text(
                        'Expiry Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 24,
                      child: Text(
                        'Quote Terms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 24,
                      child: Text(
                        'Price List',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 15,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE9E4DC), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 18,
                      child: Text(
                        p.billNumber.isEmpty ? '-' : p.billNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 24,
                      child: Text(
                        p.paidThrough.isEmpty ? '-' : p.paidThrough,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 24,
                      child: Text(
                        p.depositToAccountId.isEmpty
                            ? '-'
                            : p.depositToAccountId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF433F39),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Text(
                        _currencyFormat.format(p.amount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF433F39),
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
    );
  }
}

class BulkUpdateDialog extends StatefulWidget {
  final List<String> selectedPaymentNumbers;
  const BulkUpdateDialog({super.key, required this.selectedPaymentNumbers});

  @override
  State<BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<BulkUpdateDialog> {
  String? _selectedField;
  String? _textValue;
  DateTime? _dateValue;

  final List<String> _fields = [
    'Quote Date',
    'Salesperson',
    'Notes',
    'Reference#',
    'Quote Terms',
    'Price List',
  ];

  final List<String> _paidThroughs = [
    'Petty Cash',
    'Undeposited Funds',
    'Employee Reimbursements',
    'Bank Account',
  ];

  final List<String> _depositAccounts = [
    '123456 - Checking',
    '789012 - Savings',
    '345678 - Cash on Hand',
  ];

  final List<String> _paymentModes = [
    'Direct',
    'Inside Sales',
    'Field Sales',
    'Partner',
    'Online',
    'Walk-in',
    'Referral',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Update Quote',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field Selector Dropdown
                      Expanded(
                        child: FormDropdown<String>(
                          value: _selectedField,
                          items: _fields,
                          onChanged: (val) {
                            setState(() {
                              _selectedField = val;
                              _textValue = null;
                              _dateValue = null;
                            });
                          },
                          hint: 'Select a field',
                          height: 36,
                          showSearch: false,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Value Selector Input
                      Expanded(child: _buildValueInput()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Note banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Note: All the selected quotes will be updated with the new information and you cannot undo this action.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectedField == null
                        ? null
                        : () {
                            dynamic finalValue;
                            if (_selectedField == 'Quote Date') {
                              finalValue = _dateValue != null
                                  ? dateStrHelper(_dateValue!)
                                  : null;
                            } else {
                              finalValue = _textValue;
                            }
                            Navigator.of(context).pop({
                              'field': _selectedField,
                              'value': finalValue,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFA7F3D0),
                      disabledForegroundColor: Colors.white70,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  String dateStrHelper(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
  }

  Widget _buildValueInput() {
    if (_selectedField == null) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (_selectedField == 'Quote Date') {
      return GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateValue ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  surface: Colors.white,
                  primary: Color(0xFF10B981),
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() {
              _dateValue = picked;
            });
          }
        },
        child: AbsorbPointer(
          child: CustomTextField(
            height: 36,
            hintText: 'Select Quote Date',
            controller: TextEditingController(
              text: _dateValue == null ? '' : dateStrHelper(_dateValue!),
            ),
          ),
        ),
      );
    }

    if (_selectedField == 'Salesperson') {
      return FormDropdown<String>(
        value: _textValue,
        items: _paymentModes,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Salesperson',
        height: 36,
        showSearch: false,
      );
    }

    if (_selectedField == 'Notes') {
      return CustomTextField(
        height: 36,
        hintText: 'Enter Notes',
        onChanged: (val) {
          _textValue = val;
        },
      );
    }

    if (_selectedField == 'Reference#') {
      return CustomTextField(
        height: 36,
        hintText: 'Enter Reference#',
        onChanged: (val) {
          _textValue = val;
        },
      );
    }

    if (_selectedField == 'Quote Terms') {
      return FormDropdown<String>(
        value: _textValue,
        items: _paidThroughs,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Quote Terms',
        height: 36,
        showSearch: false,
      );
    }

    if (_selectedField == 'Price List') {
      return FormDropdown<String>(
        value: _textValue,
        items: _depositAccounts,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Price List',
        height: 36,
        showSearch: false,
      );
    }

    return Container();
  }
}

class _ViewOptionRow extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _ViewOptionRow({
    required this.label,
    required this.isSelected,
    required this.isStarred,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_ViewOptionRow> createState() => _ViewOptionRowState();
}

class _ViewOptionRowState extends State<_ViewOptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered
        ? AppTheme.primaryBlue
        : (widget.isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.transparent);
    final textColor = _isHovered
        ? Colors.white
        : (widget.isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary);
    final starColor = _isHovered
        ? Colors.white
        : (widget.isStarred
              ? const Color(0xFFF59E0B)
              : const Color(0xFFD1D5DB));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: bg,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onStarTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    widget.isStarred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: starColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewViewRow extends StatefulWidget {
  final VoidCallback onTap;

  const _NewViewRow({required this.onTap});

  @override
  State<_NewViewRow> createState() => _NewViewRowState();
}

class _NewViewRowState extends State<_NewViewRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final iconColor = _isHovered ? Colors.white : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: bg,
          child: Row(
            children: [
              Icon(LucideIcons.plusCircle, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                'New Custom View',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;

  const _ResizeHandle({required this.onDrag});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        child: Container(
          width: 12,
          color: Colors.transparent, // Ensure full 12px width is draggable
          alignment: Alignment.centerRight,
          child: Container(
            width: 2,
            height: 16,
            color: _isHovered ? const Color(0xFFD1D5DB) : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
