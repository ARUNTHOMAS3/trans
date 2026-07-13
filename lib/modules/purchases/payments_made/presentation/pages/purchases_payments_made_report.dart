import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:zerpai_erp/modules/purchases/payments_made/providers/purchases_payments_made_provider.dart';

class MockPaymentMade {
  final String date;
  final String location;
  final String paymentNumber;
  final String referenceNumber;
  final String vendorName;
  final String billNumber;
  final String mode;
  final String status;
  final double amount;
  final double unusedAmount;
  final String notes;
  final String paidThrough;
  final String depositToAccountId;

  MockPaymentMade({
    required this.date,
    required this.location,
    required this.paymentNumber,
    required this.referenceNumber,
    required this.vendorName,
    required this.billNumber,
    required this.mode,
    required this.status,
    required this.amount,
    required this.unusedAmount,
    this.notes = '',
    this.paidThrough = '',
    this.depositToAccountId = '',
  });
}

class PaymentsMadeReportPage extends ConsumerStatefulWidget {
  const PaymentsMadeReportPage({super.key});

  // Shared static list so new payments can be added from create page
  static final List<MockPaymentMade> allPayments = [];

  @override
  ConsumerState<PaymentsMadeReportPage> createState() =>
      _PaymentsMadeReportPageState();
}

class _PaymentsMadeReportPageState
    extends ConsumerState<PaymentsMadeReportPage> {
  List<MockPaymentMade> get _allPayments => PaymentsMadeReportPage.allPayments;

  // Selection state
  final Set<String> _selectedIds = {};

  // Columns configuration
  late List<ColumnConfig> _columns;

  // View/Filter menu state
  final MenuController _viewMenuController = MenuController();
  String _selectedView = 'All Payments';
  bool _viewIsStarred = false;

  // Column Widths
  late Map<String, double> _colWidths;

  bool _isLoading = false;

  Future<void> _loadPaymentsFromDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(paymentsMadeRepositoryProvider);
      final apiPayments = await repo.getPaymentsMade();

      final List<MockPaymentMade> loaded = [];
      for (final p in apiPayments) {
        loaded.add(
          MockPaymentMade(
            date: DateFormat('dd-MM-yyyy').format(p.paymentDate),
            location: 'ZABNIX PRIVATE LIMITED',
            paymentNumber: p.paymentNumber,
            referenceNumber: p.referenceNumber ?? '',
            vendorName: p.vendorName ?? 'Generic Vendor',
            billNumber: '',
            mode: p.paymentMode ?? 'Cash',
            status: p.status,
            amount: p.paymentAmount,
            unusedAmount: p.excessAmount,
            notes: p.notes ?? '',
            paidThrough: p.paidThroughAccountId,
            depositToAccountId: p.depositToAccountId ?? '',
          ),
        );
      }

      setState(() {
        PaymentsMadeReportPage.allPayments.clear();
        PaymentsMadeReportPage.allPayments.addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load payments: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentsFromDb();
    _colWidths = {
      'checkbox': 80,
      'date': 110,
      'location': 180,
      'payment_no': 100,
      'reference': 150,
      'vendor_name': 280,
      'bill_no': 100,
      'mode': 130,
      'status': 90,
      'amount': 130,
      'unused': 130,
      'actions': 50,
    };
    _columns = [
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
        label: 'Payment #',
        isVisible: true,
        orderIndex: 2,
      ),
      ColumnConfig(
        id: 'reference',
        label: 'Reference#',
        isVisible: true,
        orderIndex: 3,
      ),
      ColumnConfig(
        id: 'vendor_name',
        label: 'Vendor Name',
        isVisible: true,
        orderIndex: 4,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'bill_no',
        label: 'Bill#',
        isVisible: true,
        orderIndex: 5,
      ),
      ColumnConfig(
        id: 'mode',
        label: 'Mode',
        isVisible: true,
        orderIndex: 6,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'status',
        label: 'Status',
        isVisible: true,
        orderIndex: 7,
      ),
      ColumnConfig(
        id: 'amount',
        label: 'Amount',
        isVisible: true,
        orderIndex: 8,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'unused',
        label: 'Unused Amount',
        isVisible: true,
        orderIndex: 9,
      ),
    ];
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

  List<MockPaymentMade> _getFilteredAndSortedPayments() {
    // 1. Filter
    List<MockPaymentMade> results = List.from(_allPayments);
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
          final numA = int.tryParse(a.paymentNumber) ?? 0;
          final numB = int.tryParse(b.paymentNumber) ?? 0;
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
        case 'unused':
          comparison = a.unusedAmount.compareTo(b.unusedAmount);
          break;
        case 'created_time':
          final numA = int.tryParse(a.paymentNumber) ?? 0;
          final numB = int.tryParse(b.paymentNumber) ?? 0;
          comparison = numA.compareTo(numB);
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

  void _toggleSelectAll(bool? checked, List<MockPaymentMade> visibleRows) {
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
    final state = GoRouterState.of(context);
    context.goNamed(
      AppRoutes.paymentsMade,
      pathParameters: state.pathParameters,
      queryParameters: {
        ...state.uri.queryParameters,
        'paymentId': paymentNumber,
      },
    );
  }

  void _deselectPayment() {
    final state = GoRouterState.of(context);
    final updatedParams = Map<String, String>.from(state.uri.queryParameters);
    updatedParams.remove('paymentId');
    context.goNamed(
      state.name ?? AppRoutes.paymentsMade,
      pathParameters: state.pathParameters,
      queryParameters: updatedParams,
    );
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
            label: 'All Payments',
            isSelected: _selectedView == 'All Payments',
            isStarred: _viewIsStarred,
            onTap: () {
              setState(() {
                _selectedView = 'All Payments';
              });
              _viewMenuController.close();
            },
            onStarTap: () {
              setState(() {
                _viewIsStarred = !_viewIsStarred;
              });
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          _NewViewRow(
            onTap: () {
              _viewMenuController.close();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New Custom View clicked')),
              );
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
    final selectedPaymentId = state.uri.queryParameters['paymentId'];

    // Find the currently selected payment object for the details overlay
    MockPaymentMade? selectedPayment;
    if (selectedPaymentId != null) {
      try {
        selectedPayment = _allPayments.firstWhere(
          (p) => p.paymentNumber == selectedPaymentId,
        );
      } catch (_) {}
    }

    final visiblePayments = _getFilteredAndSortedPayments();
    final allVisibleSelected =
        visiblePayments.isNotEmpty &&
        visiblePayments.every((p) => _selectedIds.contains(p.paymentNumber));

    final scaffoldBody = Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, orgId),
            _buildSearchFilterToolbar(),
            Expanded(
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      scrollDirection: Axis.vertical,
                      child: _buildTable(visiblePayments, allVisibleSelected),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (selectedPayment != null) _buildDetailsOverlay(selectedPayment),
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ),
      ],
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
                  setState(() {
                    for (final paymentNo in _selectedIds) {
                      final index = _allPayments.indexWhere(
                        (p) => p.paymentNumber == paymentNo,
                      );
                      if (index != -1) {
                        final p = _allPayments[index];
                        String updatedDate = p.date;
                        String updatedLocation = p.location;
                        String updatedMode = p.mode;
                        String updatedStatus = p.status;
                        String updatedRef = p.referenceNumber;
                        String updatedNotes = p.notes;
                        String updatedPaidThrough = p.paidThrough;
                        String updatedDeposit = p.depositToAccountId;

                        if (field == 'Payment Date' && value is String) {
                          updatedDate = value;
                        } else if (field == 'Location' && value is String) {
                          updatedLocation = value;
                        } else if (field == 'Payment Mode' && value is String) {
                          updatedMode = value;
                        } else if (field == 'Status' && value is String) {
                          updatedStatus = value;
                        } else if (field == 'Reference#' && value is String) {
                          updatedRef = value;
                        } else if (field == 'Notes' && value is String) {
                          updatedNotes = value;
                        } else if (field == 'Paid Through' && value is String) {
                          updatedPaidThrough = value;
                        } else if (field == 'Deposit To Account ID' &&
                            value is String) {
                          updatedDeposit = value;
                        }

                        _allPayments[index] = MockPaymentMade(
                          date: updatedDate,
                          location: updatedLocation,
                          paymentNumber: p.paymentNumber,
                          referenceNumber: updatedRef,
                          vendorName: p.vendorName,
                          billNumber: p.billNumber,
                          mode: updatedMode,
                          status: updatedStatus,
                          amount: p.amount,
                          unusedAmount: p.unusedAmount,
                          notes: updatedNotes,
                          paidThrough: updatedPaidThrough,
                          depositToAccountId: updatedDeposit,
                        );
                      }
                    }
                    _selectedIds.clear();
                  });
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final confirmed = await showZerpaiConfirmationDialog(
                  context,
                  title: 'Delete Payments',
                  message:
                      'Are you sure you want to delete the selected payments? This action cannot be undone.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  variant: ZerpaiConfirmationVariant.danger,
                );
                if (confirmed) {
                  setState(() {
                    _allPayments.removeWhere(
                      (p) => _selectedIds.contains(p.paymentNumber),
                    );
                    _selectedIds.clear();
                  });
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
                  fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
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
                      fontFamily: 'Inter',
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
                        style: AppTheme.textPrimaryStyle(18, FontWeight.w600)
                            .copyWith(
                              fontFamily: 'Inter',
                              color: AppTheme.textPrimary,
                            ),
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
              context.go('/$orgId${AppRoutes.paymentsMadeCreate}');
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MenuAnchor(
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
                alignmentOffset: const Offset(-12, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  _buildSortMenuItem('Date', 'date'),
                  _buildSortMenuItem('Payment #', 'payment_no'),
                  _buildSortMenuItem('Reference#', 'reference'),
                  _buildSortMenuItem('Vendor Name', 'vendor_name'),
                  _buildSortMenuItem('Mode', 'mode'),
                  _buildSortMenuItem('Amount', 'amount'),
                  _buildSortMenuItem('Unused Amount', 'unused'),
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
                alignmentOffset: const Offset(-12, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importing payments...')),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Import Payments',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Importing applied excess payments...'),
                        ),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Import Applied Excess Payments',
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
                alignmentOffset: const Offset(-12, 0),
                submenuIcon: const WidgetStatePropertyAll(
                  Icon(LucideIcons.chevronRight, size: 14),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting payments...')),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Export Payments',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening preferences...')),
                  );
                },
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: Row(
                  children: const [
                    Icon(LucideIcons.settings, size: 14),
                    SizedBox(width: 12),
                    Text('Preferences', style: TextStyle(fontSize: 13)),
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
          _sortByField = fieldId;
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
                hintText: 'Search by Vendor, Payment #, Bill #...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
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
    List<MockPaymentMade> visiblePayments,
    bool allVisibleSelected,
  ) {
    // Columns config and widths
    final colWidths = _colWidths;

    final activeColumns = _columns.where((c) => c.isVisible).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    double totalWidth = colWidths['checkbox']! + colWidths['actions']!;
    for (final col in activeColumns) {
      totalWidth += colWidths[col.id] ?? 0;
    }

    return Container(
      width: totalWidth,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
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
                // Checkbox Column (with Sliders Menu)
                SizedBox(
                  width: colWidths['checkbox'],
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
                              onSave: (updatedColumns) {
                                setState(() {
                                  _columns = updatedColumns;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
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
                // Dynamic Header Cells
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
                    align: (col.id == 'amount' || col.id == 'unused')
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
                // Actions/Search Column Header (Removed search icon per request)
                SizedBox(width: colWidths['actions']),
              ],
            ),
          ),
          // Table Body
          if (visiblePayments.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                'No payments found matching criteria.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            )
          else
            ...visiblePayments.map((p) {
              final isChecked = _selectedIds.contains(p.paymentNumber);
              final isHovered = _hoveredRowId == p.paymentNumber;
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredRowId = p.paymentNumber),
                onExit: (_) => setState(() => _hoveredRowId = null),
                child: Container(
                  height: _wrapText ? null : 56,
                  constraints: _wrapText
                      ? const BoxConstraints(minHeight: 56)
                      : null,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFFF1F5F9)
                        : (isHovered ? const Color(0xFFF9FAFB) : Colors.white),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox (with Sliders Spacing)
                      SizedBox(
                        width: colWidths['checkbox'],
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const SizedBox(width: 28),
                            const SizedBox(width: 8),
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
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectPayment(p.paymentNumber),
                          child: Row(
                            children: [
                              // Dynamic Cells based on column order
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                      fontFamily: 'Inter',
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
                                          onTap: () =>
                                              _selectPayment(p.paymentNumber),
                                          child: Text(
                                            p.paymentNumber,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primaryBlue,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontFamily: 'Inter',
                                            ),
                                            maxLines: _wrapText ? null : 1,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
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
                                  return SizedBox(
                                    width: colWidths['status']!,
                                    child: Align(
                                      alignment: _wrapText
                                          ? Alignment.topLeft
                                          : Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: _wrapText ? 12 : 0,
                                        ),
                                        child: Text(
                                          p.status,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                            fontFamily: 'Inter',
                                          ),
                                          maxLines: _wrapText ? null : 1,
                                          overflow: _wrapText
                                              ? TextOverflow.clip
                                              : TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                if (col.id == 'amount') {
                                  return _buildCell(
                                    text: _currencyFormat.format(p.amount),
                                    width: colWidths['amount']!,
                                    align: TextAlign.right,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: p.unusedAmount > 0
                                          ? const Color(0xFF374151)
                                          : const Color(0xFF9CA3AF),
                                      fontFamily: 'Inter',
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              // Empty space for action column aligner
                              SizedBox(width: colWidths['actions']!),
                            ],
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
      padding: const EdgeInsets.only(left: 10, right: 14),
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: align,
              overflow: _wrapText ? TextOverflow.clip : TextOverflow.ellipsis,
              maxLines: _wrapText ? null : 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (isSortable && isSorted) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 13,
              color: AppTheme.primaryBlue,
            ),
          ] else if (isSortable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more, size: 13, color: Color(0xFF9CA3AF)),
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
  }) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: align == TextAlign.right
            ? (_wrapText ? Alignment.topRight : Alignment.centerRight)
            : (_wrapText ? Alignment.topLeft : Alignment.centerLeft),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: _wrapText ? 12 : 0,
          ),
          child: Text(
            text,
            style:
                textStyle ??
                const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontFamily: 'Inter',
                ),
            maxLines: _wrapText ? null : 1,
            overflow: _wrapText ? TextOverflow.clip : TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsOverlay(MockPaymentMade p) {
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
                      // Payment Receipt metadata block
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

  Widget _buildDetailsHeader(MockPaymentMade p) {
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
              'Payment ${p.paymentNumber}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
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

  Widget _buildReceiptTitleCard(MockPaymentMade p) {
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
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Payment successfully completed via ${p.mode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMetaBlock(MockPaymentMade p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT RECEIPT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
            fontFamily: 'Inter',
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
              _buildMetaRow('Payment Date', p.date),
              const Divider(height: 20, color: AppTheme.borderColor),
              _buildMetaRow('Location', p.location),
              const Divider(height: 20, color: AppTheme.borderColor),
              _buildMetaRow('Payment Mode', p.mode),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
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
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSummaryBlock(MockPaymentMade p) {
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
                'Amount Paid',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _currencyFormat.format(p.amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unused Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _currencyFormat.format(p.unusedAmount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.unusedAmount > 0
                      ? const Color(0xFFEA580C)
                      : AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillsPaidSection(MockPaymentMade p) {
    if (p.billNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILLS PAID',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Column Headers
              Container(
                color: Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bill Number',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Text(
                      'Payment Amount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              // Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.billNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(p.amount - p.unusedAmount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
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
    'Payment Mode',
    'Notes',
    'Reference#',
    'Paid Through',
    'Deposit To Account ID',
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
    'Bank Remittance',
    'Bank Transfer',
    'Card',
    'Cash',
    'Cheque',
    'Credit Card',
    'Debit Card',
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
                    'Bulk Update Vendor Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
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
                      'Note: All the selected vendor payment will be updated with the new information and you cannot undo this action.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                        fontFamily: 'Inter',
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
                            if (_selectedField == 'Payment Date') {
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
                        fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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

    if (_selectedField == 'Payment Mode') {
      return FormDropdown<String>(
        value: _textValue,
        items: _paymentModes,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Payment Mode',
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

    if (_selectedField == 'Paid Through') {
      return FormDropdown<String>(
        value: _textValue,
        items: _paidThroughs,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Paid Through',
        height: 36,
        showSearch: false,
      );
    }

    if (_selectedField == 'Deposit To Account ID') {
      return FormDropdown<String>(
        value: _textValue,
        items: _depositAccounts,
        onChanged: (val) {
          setState(() {
            _textValue = val;
          });
        },
        hint: 'Select Deposit To Account ID',
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
                    fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
