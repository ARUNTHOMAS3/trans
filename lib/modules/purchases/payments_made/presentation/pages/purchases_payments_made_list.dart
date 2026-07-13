import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/web_safe_platform_file.dart';


// ─── Models ───────────────────────────────────────────────────────────────────

class PaymentMade {
  final String? dbId;
  final String id; // maps to paymentNumber
  final String date;
  final String location;
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

  // Custom mock company details to display in the document header (simulating RetainerInvoiceOverviewScreen)
  final String companyName;
  final List<String> companyAddress;
  final String companyGstin;
  final String companyPhone;
  final String companyEmail;
  final List<String> vendorAddress;
  final String vendorGstin;
  final String placeOfSupply;
  final String amountInWords;

  const PaymentMade({
    this.dbId,
    required this.id,
    required this.date,
    required this.location,
    required this.referenceNumber,
    required this.vendorName,
    required this.billNumber,
    required this.mode,
    required this.status,
    required this.amount,
    required this.unusedAmount,
    this.notes = '',
    this.paidThrough = 'Bandhan Bank',
    this.depositToAccountId = '',
    this.companyName = 'ZABNIX PRIVATE LIMITED',
    this.companyAddress = const [
      'PERINTHALMANNA',
      'MALAPPURAM Kerala 679322',
      'India',
    ],
    this.companyGstin = '32AACCZ4912F1ZL',
    this.companyPhone = '8086355500',
    this.companyEmail = 'zabnixprivatelimited@gmail.com',
    this.vendorAddress = const [
      '1545, Obeya Brio, Sector 1, 19th Main Road,',
      'HSR Layout',
      'Bengaluru Urban',
      '560102 Karnataka',
      'India',
    ],
    this.vendorGstin = '29AAHCG3435D1ZQ',
    this.placeOfSupply = 'Kerala (32)',
    this.amountInWords = 'Indian Rupee Seven Thousand Eighty Only',
  });
}

class FilterItem {
  final String label;
  const FilterItem(this.label);
}

// ─── Mock Data ───────────────────────────────────────────────────────────────

const List<PaymentMade> _mockPayments = [
  PaymentMade(
    id: '97',
    date: '23-04-2026',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: '',
    vendorName: 'ZERPAI TESTING',
    billNumber: '453fd',
    mode: 'Cash',
    status: 'PAID',
    amount: 69.00,
    unusedAmount: 0.00,
    amountInWords: 'Indian Rupee Sixty Nine Only',
  ),
  PaymentMade(
    id: '96',
    date: '19-11-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'GYANKAAR TECHNOLOGIES PRIVATE LIMITED',
    billNumber: '',
    mode: 'Cash',
    status: 'PAID',
    amount: 7080.00,
    unusedAmount: 7080.00,
    amountInWords: 'Indian Rupee Seven Thousand Eighty Only',
  ),
  PaymentMade(
    id: '95',
    date: '10-11-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    billNumber: '',
    mode: 'Cash',
    status: 'PAID',
    amount: 133000.00,
    unusedAmount: 133000.00,
    amountInWords: 'Indian Rupee One Lakh Thirty Three Thousand Only',
  ),
  PaymentMade(
    id: '94',
    date: '03-11-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'GYANKAAR TECHNOLOGIES PRIVATE LIMITED',
    billNumber: '',
    mode: 'Cash',
    status: 'PAID',
    amount: 1416.00,
    unusedAmount: 1416.00,
    amountInWords: 'Indian Rupee One Thousand Four Hundred Sixteen Only',
  ),
  PaymentMade(
    id: '93',
    date: '30-10-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    billNumber: '',
    mode: 'Cash',
    status: 'PAID',
    amount: 25000.00,
    unusedAmount: 25000.00,
    amountInWords: 'Indian Rupee Twenty Five Thousand Only',
  ),
  PaymentMade(
    id: '88',
    date: '28-10-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 25000.00,
    unusedAmount: 25000.00,
    amountInWords: 'Indian Rupee Twenty Five Thousand Only',
  ),
  PaymentMade(
    id: '89',
    date: '27-10-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'NUBINIX TECHNOLOGIES',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 22780.64,
    unusedAmount: 22780.64,
    amountInWords:
        'Indian Rupee Twenty Two Thousand Seven Hundred Eighty and Paise Sixty Four Only',
  ),
  PaymentMade(
    id: '90',
    date: '16-10-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'NUBINIX TECHNOLOGIES',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 46979.00,
    unusedAmount: 46979.00,
    amountInWords:
        'Indian Rupee Forty Six Thousand Nine Hundred Seventy Nine Only',
  ),
  PaymentMade(
    id: '91',
    date: '23-09-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'NUBINIX TECHNOLOGIES',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 49228.46,
    unusedAmount: 49228.46,
    amountInWords:
        'Indian Rupee Forty Nine Thousand Two Hundred Twenty Eight and Paise Forty Six Only',
  ),
  PaymentMade(
    id: '92',
    date: '13-06-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 30000.00,
    unusedAmount: 30000.00,
    amountInWords: 'Indian Rupee Thirty Thousand Only',
  ),
  PaymentMade(
    id: '87',
    date: '24-04-2025',
    location: 'ZABNIX PRIVATE LIMITED',
    referenceNumber: 'xxxxxxxxxxxx6000',
    vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    billNumber: '',
    mode: 'Bank Transfer',
    status: 'PAID',
    amount: 10000.00,
    unusedAmount: 10000.00,
    amountInWords: 'Indian Rupee Ten Thousand Only',
  ),
];

// ─── Screen Widget ───────────────────────────────────────────────────────────

class PaymentsMadeOverviewPage extends ConsumerStatefulWidget {
  const PaymentsMadeOverviewPage({super.key});

  @override
  ConsumerState<PaymentsMadeOverviewPage> createState() =>
      _PaymentsMadeOverviewPageState();
}

// ─── State ───────────────────────────────────────────────────────────────────

class _PaymentsMadeOverviewPageState extends ConsumerState<PaymentsMadeOverviewPage> {
  late List<PaymentMade> _payments;
  late PaymentMade _selectedPayment;
  String _selectedFilter = 'All';
  bool _isLoading = false;

  // Filter dropdown (MenuAnchor)
  final MenuController _filterMenuController = MenuController();
  // PDF/Print dropdown (MenuAnchor)
  final MenuController _pdfPrintMenuController = MenuController();
  // Right action bar more dropdown (MenuAnchor)
  final MenuController _rightMoreMenuController = MenuController();
  // Bulk actions dropdown (MenuAnchor)
  final MenuController _bulkMenuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _starredValues = {'All', 'Paid'};
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;

  // More-menu overlay (three-dot in left header)
  final LayerLink _moreLink = LayerLink();
  OverlayEntry? _moreMenuOverlayEntry;
  bool _isMoreMenuOpen = false;
  String? _activeSubMenu;

  final LayerLink _attachmentLink = LayerLink();
  OverlayEntry? _attachmentOverlayEntry;
  bool _isAttachmentPopoverOpen = false;
  bool _showCommentsPanel = false;

  // Row checkbox selection
  final Set<String> _checkedIds = {};
  String? _hoveredId;

  // Template chooser panel
  String _selectedTemplate = 'Standard Template';

  List<PlatformFile> _uploadedFiles = [];

  final List<FilterItem> _allFilters = [
    const FilterItem('All'),
    const FilterItem('Paid'),
  ];

  @override
  void initState() {
    super.initState();
    _payments = List.from(_mockPayments);
    _selectedPayment = _payments.first;
    _loadPaymentsFromDb();
    _loadAttachmentsForSelectedPayment();
  }

  Future<void> _loadPaymentsFromDb() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('payment_made_master')
          .select('*, vendors(*), payment_made_tax(*)')
          .order('payment_date', ascending: false);

      final loaded = rows.map<PaymentMade>((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final vendor = row['vendors'] is Map
            ? Map<String, dynamic>.from(row['vendors'] as Map)
            : <String, dynamic>{};
        final taxRows = row['payment_made_tax'] as List<dynamic>? ?? const [];
        final taxRow = taxRows.isNotEmpty && taxRows.first is Map
            ? Map<String, dynamic>.from(taxRows.first as Map)
            : <String, dynamic>{};
        final paymentDate = DateTime.tryParse(
          (row['payment_date'] ?? '').toString(),
        );

        return PaymentMade(
          dbId: row['id']?.toString() ?? '',
          id: _firstNonEmpty([
                row['payment_number'],
                row['id'],
              ]) ??
              '',
          date: paymentDate != null
              ? DateFormat('dd-MM-yyyy').format(paymentDate)
              : '',
          location: 'ZABNIX PRIVATE LIMITED',
          referenceNumber: (row['reference_number'] ?? '').toString(),
          vendorName:
              _firstNonEmpty([
                vendor['display_name'],
                vendor['displayName'],
                vendor['company_name'],
                vendor['companyName'],
                vendor['vendor_name'],
                row['vendor_name'],
              ]) ??
              'Generic Vendor',
          billNumber: '',
          mode: (row['payment_mode'] ?? 'Cash').toString(),
          status: (row['status'] ?? 'draft').toString().toUpperCase(),
          amount:
              double.tryParse((row['payment_amount'] ?? '0').toString()) ?? 0.0,
          unusedAmount:
              double.tryParse((row['excess_amount'] ?? '0').toString()) ?? 0.0,
          notes: (row['notes'] ?? '').toString(),
          paidThrough: (row['paid_through_account_id'] ?? '').toString(),
          depositToAccountId: (row['deposit_to_account_id'] ?? '').toString(),
          vendorGstin:
              _firstNonEmpty([vendor['gstin'], row['vendor_gstin']]) ??
              '29AAHCG3435D1ZQ',
          placeOfSupply:
              _firstNonEmpty([
                taxRow['source_of_supply'],
                row['place_of_supply'],
              ]) ??
              'Kerala (32)',
        );
      }).toList();

      if (!mounted || loaded.isEmpty) return;

      final state = GoRouterState.of(context);
      final selectedQueryId = state.uri.queryParameters['paymentId'];
      final nextSelected = selectedQueryId == null
          ? loaded.first
          : loaded.firstWhere(
              (p) => p.id == selectedQueryId,
              orElse: () => loaded.first,
            );

      setState(() {
        _payments = loaded;
        _selectedPayment = nextSelected;
      });
      _loadAttachmentsForSelectedPayment();
    } catch (e) {
      debugPrint('Error loading payments made: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttachmentsForSelectedPayment() async {
    try {
      final supabase = Supabase.instance.client;
      String? dbPaymentId = _selectedPayment.dbId;

      if (dbPaymentId == null || dbPaymentId.isEmpty) {
        final masterRows = await supabase
            .from('payment_made_master')
            .select('id')
            .eq('payment_number', _selectedPayment.id);

        if (masterRows.isNotEmpty) {
          dbPaymentId = masterRows.first['id'] as String;
        }
      }

      if (dbPaymentId == null || dbPaymentId.isEmpty) {
        setState(() {
          _uploadedFiles = [];
        });
        return;
      }

      final rows = await supabase
          .from('payment_made_attachments')
          .select('*')
          .eq('payment_made_id', dbPaymentId);
          
      final List<PlatformFile> files = [];
      for (final r in rows) {
        files.add(WebSafePlatformFile(
          name: r['file_name']?.toString() ?? '',
          size: int.tryParse(r['file_size']?.toString() ?? '0') ?? 0,
          path: r['file_path']?.toString(),
        ));
      }
      
      setState(() {
        _uploadedFiles = files;
      });
    } catch (e) {
      debugPrint('Error loading attachments: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    final paymentId = state.uri.queryParameters['paymentId'];
    if (paymentId != null) {
      final match = _payments.firstWhere(
        (p) => p.id == paymentId,
        orElse: () => _payments.first,
      );
      if (_selectedPayment != match) {
        setState(() {
          _selectedPayment = match;
        });
        _loadAttachmentsForSelectedPayment();
      }
    }
  }

  void _selectPayment(PaymentMade p) {
    setState(() {
      _selectedPayment = p;
    });
    _loadAttachmentsForSelectedPayment();
    final state = GoRouterState.of(context);
    context.goNamed(
      state.name ?? AppRoutes.paymentsMade,
      pathParameters: state.pathParameters,
      queryParameters: {...state.uri.queryParameters, 'paymentId': p.id},
    );
  }

  void _deselectPayment() {
    final state = GoRouterState.of(context);
    final updatedParams = Map<String, String>.from(state.uri.queryParameters);
    updatedParams.remove('paymentId');
    context.goNamed(
      AppRoutes.paymentsMadeReport,
      pathParameters: state.pathParameters,
      queryParameters: updatedParams,
    );
  }

  // ─── Filter Dropdown ──────────────────────────────────────────────────────────

  Widget _buildFilterDropdownContent() {
    final query = _searchQuery.toLowerCase();
    final favList = _allFilters
        .where((f) => _starredValues.contains(f.label))
        .where((f) => f.label.toLowerCase().contains(query))
        .toList();
    final defaultList = _allFilters
        .where((f) => f.label.toLowerCase().contains(query))
        .toList();

    return StatefulBuilder(
      builder: (context, setMenu) {
        return Container(
          width: 270,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          LucideIcons.search,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            setMenu(() {});
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search Filters',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            setMenu(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              LucideIcons.x,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Scrollable sections
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FAVORITES
                      _filterSectionHeader(
                        title: 'FAVORITES',
                        count: favList.length,
                        isExpanded: _favoritesExpanded,
                        onTap: () => setState(
                          () => _favoritesExpanded = !_favoritesExpanded,
                        ),
                      ),
                      if (_favoritesExpanded)
                        ...favList.map(
                          (f) =>
                              _filterOptionRow(label: f.label, isStarred: true),
                        ),

                      // DEFAULT FILTERS
                      _filterSectionHeader(
                        title: 'DEFAULT FILTERS',
                        count: defaultList.length,
                        isExpanded: _defaultFiltersExpanded,
                        onTap: () => setState(
                          () => _defaultFiltersExpanded =
                              !_defaultFiltersExpanded,
                        ),
                      ),
                      if (_defaultFiltersExpanded)
                        ...defaultList.map(
                          (f) => _filterOptionRow(
                            label: f.label,
                            isStarred: _starredValues.contains(f.label),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterSectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: const Color(0xFFF9FAFB),
        child: Row(
          children: [
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 13,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOptionRow({required String label, required bool isStarred}) {
    final isSelected = _selectedFilter == label;
    return _FilterOptionRow(
      label: label,
      isStarred: isStarred,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedFilter = label);
        _filterMenuController.close();
      },
      onStarTap: () {
        setState(() {
          if (_starredValues.contains(label)) {
            _starredValues.remove(label);
          } else {
            _starredValues.add(label);
          }
        });
      },
    );
  }

  // ─── More Menu (left header three-dot) ──────────────────────────────────────

  void _toggleMoreMenu() {
    if (_isMoreMenuOpen) {
      _closeMoreMenu();
    } else {
      _openMoreMenu();
    }
  }

  void _openMoreMenu() {
    _moreMenuOverlayEntry = _createMoreMenuOverlayEntry();
    Overlay.of(context).insert(_moreMenuOverlayEntry!);
    setState(() {
      _isMoreMenuOpen = true;
      _activeSubMenu = null;
    });
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isMoreMenuOpen = false;
        _activeSubMenu = null;
      });
    }
  }

  OverlayEntry _createMoreMenuOverlayEntry() {
    String? hoveredSubMenuItem;
    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) {
          Widget? subMenuWidget;
          if (_activeSubMenu == 'Sort by') {
            subMenuWidget = _buildSortBySubMenu(
              setStateOverlay,
              hoveredSubMenuItem,
              (val) => setStateOverlay(() => hoveredSubMenuItem = val),
            );
          } else if (_activeSubMenu == 'Export') {
            subMenuWidget = _buildExportSubMenu(
              setStateOverlay,
              hoveredSubMenuItem,
              (val) => setStateOverlay(() => hoveredSubMenuItem = val),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMoreMenu,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.transparent)),
                CompositedTransformFollower(
                  link: _moreLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MainMenuItemWidget(
                                icon: LucideIcons.arrowUpDown,
                                label: 'Sort by',
                                hasSubMenu: true,
                                isActive: _activeSubMenu == 'Sort by',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = 'Sort by';
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: () {},
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.download,
                                label: 'Import Payments Made',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.upload,
                                label: 'Export',
                                hasSubMenu: true,
                                isActive: _activeSubMenu == 'Export',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = 'Export';
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: () {},
                              ),
                              const Divider(
                                height: 8,
                                color: Color(0xFFD0D0D0),
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.settings,
                                label: 'Preferences',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: () {
                                  _closeMoreMenu();
                                  _showPreferencesDialog();
                                },
                              ),
                              const Divider(
                                height: 8,
                                color: Color(0xFFD0D0D0),
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.refreshCw,
                                label: 'Refresh List',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (subMenuWidget != null) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: EdgeInsets.only(
                            top: _activeSubMenu == 'Export' ? 76 : 4,
                          ),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: subMenuWidget,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBySubMenu(
    void Function(void Function()) setStateOverlay,
    String? hoveredSubMenuItem,
    void Function(String?) setHovered,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubMenuItem('Payment Date', hoveredSubMenuItem, setHovered),
          _buildSubMenuItem('Payment #', hoveredSubMenuItem, setHovered),
          _buildSubMenuItem('Vendor Name', hoveredSubMenuItem, setHovered),
          _buildSubMenuItem('Amount', hoveredSubMenuItem, setHovered),
        ],
      ),
    );
  }

  Widget _buildExportSubMenu(
    void Function(void Function()) setStateOverlay,
    String? hoveredSubMenuItem,
    void Function(String?) setHovered,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubMenuItem('Export as PDF', hoveredSubMenuItem, setHovered),
          _buildSubMenuItem('Export as XLS', hoveredSubMenuItem, setHovered),
        ],
      ),
    );
  }

  Widget _buildSubMenuItem(
    String label,
    String? hoveredItem,
    void Function(String?) setHovered,
  ) {
    final isHovered = hoveredItem == label;
    return MouseRegion(
      onEnter: (_) => setHovered(label),
      onExit: (_) => setHovered(null),
      child: InkWell(
        onTap: _closeMoreMenu,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          color: isHovered ? AppTheme.primaryBlue : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const ConfigurePaymentNumberPreferencesDialog(
          currentLocation: 'ZABNIX PRIVATE LIMITED',
          currentSeries: 'Default Transaction Series',
        );
      },
    );
  }

  // ─── Attachments Popover ────────────────────────────────────────────────────

  void _toggleAttachmentPopover() {
    if (_isAttachmentPopoverOpen) {
      _closeAttachmentPopover();
    } else {
      _openAttachmentPopover();
    }
  }

  void _openAttachmentPopover() {
    _attachmentOverlayEntry = _createAttachmentOverlayEntry();
    Overlay.of(context).insert(_attachmentOverlayEntry!);
    setState(() => _isAttachmentPopoverOpen = true);
  }

  void _closeAttachmentPopover() {
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
    if (mounted) {
      setState(() => _isAttachmentPopoverOpen = false);
    }
  }

  OverlayEntry _createAttachmentOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeAttachmentPopover,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_uploadedFiles.length} File(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_uploadedFiles.isEmpty)
                      Container(
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Text(
                          'No attachments found.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _uploadedFiles.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.file,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    String? fileUrl;
                                    try {
                                      fileUrl = file.path;
                                    } catch (_) {}
                                    if (fileUrl != null) {
                                      try {
                                        final supabase = Supabase.instance.client;
                                        await supabase
                                            .from('payment_made_attachments')
                                            .delete()
                                            .eq('file_path', fileUrl);
                                      } catch (e) {
                                        debugPrint('Error deleting attachment: $e');
                                      }
                                    }
                                    await _loadAttachmentsForSelectedPayment();
                                    _closeAttachmentPopover();
                                    _openAttachmentPopover();
                                  },
                                  child: const Icon(
                                    LucideIcons.trash2,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FileUploadButton(
                          files: _uploadedFiles,
                          onFilesChanged: (files) async {
                            final currentNames = _uploadedFiles.map((f) => f.name).toSet();
                            final newFiles = files.where((f) => !currentNames.contains(f.name)).toList();
                            
                            if (newFiles.isNotEmpty) {
                              try {
                                final supabase = Supabase.instance.client;
                                final masterRows = await supabase
                                    .from('payment_made_master')
                                    .select('id')
                                    .eq('payment_number', _selectedPayment.id);
                                    
                                String dbPaymentId;
                                if (masterRows.isEmpty) {
                                  final vendorRows = await supabase
                                      .from('vendors')
                                      .select('id')
                                      .limit(1);
                                  final String vendorId = vendorRows.isNotEmpty
                                      ? vendorRows.first['id'] as String
                                      : '66d79887-be98-40ab-ac40-9e0a008f9d8a';

                                  final accountRows = await supabase
                                      .from('accounts')
                                      .select('id')
                                      .limit(1);
                                  final String paidThroughId = accountRows.isNotEmpty
                                      ? accountRows.first['id'] as String
                                      : '90d2275a-33d0-4fe7-9295-6a59ee0ddce4';

                                  final insertResult = await supabase
                                      .from('payment_made_master')
                                      .insert({
                                        'entity_id': '66d79887-be98-40ab-ac40-9e0a008f9d8a',
                                        'vendor_id': vendorId,
                                        'payment_type': 'VENDOR_ADVANCE',
                                        'payment_number': _selectedPayment.id,
                                        'payment_date': DateTime.now().toIso8601String().split('T')[0],
                                        'payment_amount': _selectedPayment.amount,
                                        'paid_through_account_id': paidThroughId,
                                        'status': _selectedPayment.status.toLowerCase(),
                                        'notes': _selectedPayment.notes,
                                      })
                                      .select('id')
                                      .single();
                                  dbPaymentId = insertResult['id'] as String;
                                } else {
                                  dbPaymentId = masterRows.first['id'] as String;
                                }

                                final storage = StorageService();
                                for (final file in newFiles) {
                                  final fileUrl = await storage.uploadPaymentAttachment(file);
                                  if (fileUrl != null) {
                                    await supabase.from('payment_made_attachments').insert({
                                      'payment_made_id': dbPaymentId,
                                      'file_name': file.name,
                                      'file_path': fileUrl,
                                      'original_file_name': file.name,
                                      'file_size': file.size,
                                      'file_type': file.extension ?? 'application/octet-stream',
                                      'remarks': '',
                                    });
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error saving uploaded attachments: $e');
                              }
                            }
                            await _loadAttachmentsForSelectedPayment();
                            _closeAttachmentPopover();
                            _openAttachmentPopover();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Comments composer ──────────────────────────────────────────────────────

  Widget _buildCommentsHistoryPanel(NumberFormat currencyFormat) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        child: Container(
          width: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comments & History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showCommentsPanel = false),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.red.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentComposer(),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text(
                            'ALL COMMENTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'zabnixprivatelimited',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${_selectedPayment.date} 07:40 PM',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Payment Receipt created for '
                                    '${currencyFormat.format(_selectedPayment.amount)}',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentComposer() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            color: const Color(0xFFF4F6F8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              children: [
                Text(
                  'B',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 22),
                Text(
                  'I',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 22),
                Text(
                  'U',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Add Comment',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF1DCC6B);
      case 'VOID':
        return AppTheme.errorRed;
      case 'DRAFT':
      default:
        return Colors.blueGrey.shade300;
    }
  }

  // ─── Main Build Method ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;

    final displayPayments = _isLoading && _payments.isEmpty
        ? List.generate(5, (index) => PaymentMade(
            id: 'loading-$index',
            date: '01-01-2026',
            location: 'Main Location',
            referenceNumber: 'REF-XXXXX',
            vendorName: 'Loading Vendor Name',
            billNumber: 'BILL-XXXXX',
            mode: 'Cash',
            status: 'PAID',
            amount: 10000.0,
            unusedAmount: 0.0,
            notes: 'loading notes',
            paidThrough: 'Petty Cash',
            depositToAccountId: '1',
            companyName: 'Loading Company Name',
            companyAddress: ['123 Main St', 'City, Country'],
            companyGstin: '29AAHCG3435D1ZQ',
            companyPhone: '1234567890',
            companyEmail: 'loading@email.com',
            vendorGstin: '29AAHCG3435D1ZQ',
            placeOfSupply: 'Kerala (32)',
          ))
        : _payments;

    // Apply Filter & Search Query
    final filteredPayments = displayPayments.where((p) {
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Paid' && p.status.toUpperCase() != 'PAID') {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return p.vendorName.toLowerCase().contains(query) ||
            p.id.toLowerCase().contains(query) ||
            p.amount.toString().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeletonizer(
        enabled: _isLoading,
        child: Stack(
          children: [
            SplitListDetailLayout(
              leftWidth: 320,
              leftHeader: _buildLeftHeader(filteredPayments),
              leftBody: _buildLeftList(filteredPayments, currencyFormat),
              rightHeader: _buildRightHeader(),
              rightBody: _buildRightBody(currencyFormat, orgSettings),
            ),
            if (_showCommentsPanel) _buildCommentsHistoryPanel(currencyFormat),
          ],
        ),
      ),
    );
  }

  // ─── Left Panel Header ──────────────────────────────────────────────────────

  Widget _buildLeftHeader(List<PaymentMade> filteredList) {
    // Bulk actions bar
    if (_checkedIds.isNotEmpty) {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _checkedIds.length == filteredList.length ? true : null,
                tristate: true,
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) {
                  setState(() {
                    if (_checkedIds.length == filteredList.length) {
                      _checkedIds.clear();
                    } else {
                      _checkedIds
                        ..clear()
                        ..addAll(filteredList.map((e) => e.id));
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            MenuAnchor(
              controller: _bulkMenuController,
              style: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.white),
                surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                elevation: WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
              builder: (context, controller, child) {
                return OutlinedButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Bulk Actions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        controller.isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                );
              },
              menuChildren: [
                _BulkActionMenuItem(
                  label: 'Bulk Update',
                  onTap: () async {
                    _bulkMenuController.close();
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => _BulkUpdateDialog(
                        selectedPaymentNumbers: _checkedIds.toList(),
                      ),
                    );
                    if (result != null) {
                      final field = result['field'] as String;
                      final value = result['value'];
                      setState(() {
                        for (final paymentId in _checkedIds) {
                          final index = _payments.indexWhere(
                            (p) => p.id == paymentId,
                          );
                          if (index != -1) {
                            final p = _payments[index];
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
                            } else if (field == 'Payment Mode' &&
                                value is String) {
                              updatedMode = value;
                            } else if (field == 'Status' && value is String) {
                              updatedStatus = value;
                            } else if (field == 'Reference#' &&
                                value is String) {
                              updatedRef = value;
                            } else if (field == 'Notes' && value is String) {
                              updatedNotes = value;
                            } else if (field == 'Paid Through' &&
                                value is String) {
                              updatedPaidThrough = value;
                            } else if (field == 'Deposit To Account ID' &&
                                value is String) {
                              updatedDeposit = value;
                            }

                            _payments[index] = PaymentMade(
                              dbId: p.dbId,
                              id: p.id,
                              date: updatedDate,
                              location: updatedLocation,
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
                        _checkedIds.clear();
                        final newSelected = _payments.firstWhere(
                          (p) => p.id == _selectedPayment.id,
                          orElse: () => _payments.first,
                        );
                        _selectedPayment = newSelected;
                      });
                    }
                  },
                ),
                _BulkActionMenuItem(
                  label: 'Delete',
                  onTap: () async {
                    _bulkMenuController.close();
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
                        _payments.removeWhere(
                          (p) => _checkedIds.contains(p.id),
                        );
                        _checkedIds.clear();
                        if (_payments.isNotEmpty) {
                          final stillExists = _payments.any(
                            (p) => p.id == _selectedPayment.id,
                          );
                          if (!stillExists) {
                            _selectedPayment = _payments.first;
                          }
                        } else {
                          _deselectPayment();
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(width: AppTheme.space12),
            Container(width: 1, height: 20, color: AppTheme.borderColor),
            const SizedBox(width: AppTheme.space12),
            // Selected count badge — matches report.dart style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_checkedIds.length}',
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
            // Esc / close — matches report.dart style
            InkWell(
              onTap: () {
                setState(() {
                  _checkedIds.clear();
                });
              },
              child: Icon(Icons.close, color: AppTheme.errorRed, size: 16),
            ),
          ],
        ),
      );
    }

    // Normal filter-integrated header
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          MenuAnchor(
            controller: _filterMenuController,
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: WidgetStatePropertyAll(8),
            ),
            builder: (context, controller, child) {
              final isOpen = controller.isOpen;
              return InkWell(
                onTap: () => isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter == 'All'
                            ? 'All Payments'
                            : _selectedFilter,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Icon(
                        isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [_buildFilterDropdownContent()],
          ),
          const Spacer(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              onPressed: () {
                final orgId = resolveOrgSystemId(context);
                context.go('/$orgId${AppRoutes.paymentsMadeCreate}');
              },
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          CompositedTransformTarget(
            link: _moreLink,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(4),
                color: _isMoreMenuOpen ? AppTheme.bgHover : Colors.white,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onPressed: _toggleMoreMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Left Panel List ────────────────────────────────────────────────────────

  Widget _buildLeftList(
    List<PaymentMade> filteredList,
    NumberFormat currencyFormat,
  ) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: filteredList.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderColor),
        itemBuilder: (context, index) {
          final pay = filteredList[index];
          final isDetailSelected = pay.id == _selectedPayment.id;
          final isChecked = _checkedIds.contains(pay.id);

          Color rowBg = Colors.transparent;
          if (isChecked) {
            rowBg = AppTheme.primaryBlue.withValues(alpha: 0.06);
          } else if (isDetailSelected) {
            rowBg = AppTheme.selectionActiveBg;
          } else if (_hoveredId == pay.id) {
            rowBg = AppTheme.bgHover;
          }

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredId = pay.id),
            onExit: (_) => setState(() {
              if (_hoveredId == pay.id) _hoveredId = null;
            }),
            child: GestureDetector(
              onTap: () => _selectPayment(pay),
              child: Container(
                color: rowBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppTheme.primaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(
                            color: Color(0xFFB0B8C1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _checkedIds.add(pay.id);
                              } else {
                                _checkedIds.remove(pay.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  pay.vendorName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormat.format(pay.amount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Row(
                            children: [
                              Text(
                                pay.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space4),
                              const Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space4),
                              Flexible(
                                child: Text(
                                  pay.mode,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            pay.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(pay.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Right Detail Header ────────────────────────────────────────────────────

  Widget? _buildRightHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Location: ${_selectedPayment.location}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selectedPayment.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CompositedTransformTarget(
                link: _attachmentLink,
                child: _buildIconButton(
                  LucideIcons.paperclip,
                  onTap: _toggleAttachmentPopover,
                  isActive: _isAttachmentPopoverOpen,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              _buildIconButton(
                LucideIcons.messageSquare,
                onTap: () =>
                    setState(() => _showCommentsPanel = !_showCommentsPanel),
                isActive: _showCommentsPanel,
              ),
              const SizedBox(width: AppTheme.space8),
              InkWell(
                onTap: _deselectPayment,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FB),
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor),
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Row(
            children: [
              _buildFlatActionTab(LucideIcons.pencil, 'Edit'),
              _buildTabSeparator(),
              _buildFlatActionTab(LucideIcons.mail, 'Send Email'),
              _buildTabSeparator(),
              MenuAnchor(
                controller: _pdfPrintMenuController,
                style: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  elevation: WidgetStatePropertyAll(8),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      side: BorderSide(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.fileText,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space6),
                        const Text(
                          'PDF/Print',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space2),
                        Icon(
                          controller.isOpen
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  );
                },
                menuChildren: [
                  _BulkActionMenuItem(
                    label: 'PDF',
                    icon: LucideIcons.fileText,
                    onTap: () {
                      _pdfPrintMenuController.close();
                    },
                  ),
                  _BulkActionMenuItem(
                    label: 'Print',
                    icon: LucideIcons.printer,
                    onTap: () {
                      _pdfPrintMenuController.close();
                    },
                  ),
                ],
              ),
              _buildTabSeparator(),
              MenuAnchor(
                controller: _rightMoreMenuController,
                style: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  elevation: WidgetStatePropertyAll(8),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      side: BorderSide(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                builder: (context, controller, child) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isOpen
                              ? const Color(0xFFE9EDF0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          LucideIcons.moreHorizontal,
                          size: 16,
                          color: controller.isOpen
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
                menuChildren: [
                  _BulkActionMenuItem(
                    label: 'Mark As Void',
                    icon: LucideIcons.ban,
                    onTap: () {
                      _rightMoreMenuController.close();
                    },
                  ),
                  _BulkActionMenuItem(
                    label: 'Clone',
                    icon: LucideIcons.copy,
                    onTap: () {
                      _rightMoreMenuController.close();
                    },
                  ),
                  _BulkActionMenuItem(
                    label: 'Delete',
                    icon: LucideIcons.trash2,
                    onTap: () {
                      _rightMoreMenuController.close();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE9EDF0) : Colors.transparent,
        border: Border.all(
          color: isActive ? AppTheme.primaryBlue : AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 14,
          color:
              color ??
              (isActive ? AppTheme.primaryBlue : AppTheme.textSecondary),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildFlatActionTab(IconData icon, String label) {
    return InkWell(
      onTap: () {
        if (label != 'Edit') return;
        final orgId = resolveOrgSystemId(context);
        context.go(
          '/$orgId${AppRoutes.paymentsMadeCreate}'
          '?paymentId=${Uri.encodeQueryComponent(_selectedPayment.dbId ?? '')}'
          '&paymentNumber=${Uri.encodeQueryComponent(_selectedPayment.id)}',
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.space6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSeparator() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space14),
      color: AppTheme.borderColor,
    );
  }

  Widget _buildFieldRow(String label, Widget valueWidget) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.topLeft, child: valueWidget),
          ),
        ],
      ),
    );
  }

  // ─── Right Detail Body ─────────────────────────────────────────────────────

  Widget _buildLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 160,
        height: 64,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildLogoFallback(),
        ),
      );
    }
    return _buildLogoFallback();
  }

  Widget _buildLogoFallback() {
    return Container(
      width: 160,
      height: 64,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text(
        'LOGO',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          letterSpacing: 0.8,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildRightBody(NumberFormat currencyFormat, OrgSettings? orgSettings) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // Warning Banner
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This transaction is categorized in Bandhan Bank. Hence, some fields cannot be modified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Uncategorize now >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // White Paper Container
                        Container(
                            width: 720,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(
                                    AppTheme.space40,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Header: Logo left | Company name+address right-aligned ──
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Logo box
                                          _buildLogo(orgSettings),
                                          const SizedBox(width: 24),
                                          // Company name + address (grey), left-aligned, close to logo
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedPayment.companyName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                    fontFamily: 'Inter',
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                ..._selectedPayment
                                                    .companyAddress
                                                    .map(
                                                      (line) => Text(
                                                        line,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF6B7280,
                                                            ),
                                                          fontFamily: 'Inter',
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                Text(
                                                  'GSTIN ${_selectedPayment.companyGstin}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                    fontFamily: 'Inter',
                                                    height: 1.5,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedPayment.companyPhone,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                    fontFamily: 'Inter',
                                                    height: 1.5,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedPayment.companyEmail,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                    fontFamily: 'Inter',
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 70),
                                      // ── "PAYMENTS MADE" heading with top divider ──
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      const SizedBox(height: 14),
                                      const Center(
                                        child: Text(
                                          'PAYMENTS MADE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4B5563),
                                            letterSpacing: 2.0,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      const SizedBox(height: 20),
                                      // ── Main split: fields left | green card right ──
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ── Left: field rows ──
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldRow(
                                                  'Payment#',
                                                  Text(
                                                    _selectedPayment.id,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Payment Date',
                                                  Text(
                                                    _selectedPayment.date,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Reference Number',
                                                  Text(
                                                    _selectedPayment
                                                            .referenceNumber
                                                            .isEmpty
                                                        ? '-'
                                                        : _selectedPayment
                                                              .referenceNumber,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Paid To',
                                                  Text(
                                                    _selectedPayment.vendorName
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color:
                                                          AppTheme.primaryBlue,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Place Of Supply',
                                                  Text(
                                                    _selectedPayment
                                                        .placeOfSupply,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Payment Mode',
                                                  Text(
                                                    _selectedPayment.mode,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Paid Through',
                                                  Text(
                                                    _selectedPayment
                                                        .paidThrough,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Amount Paid In Words',
                                                  Text(
                                                    _selectedPayment
                                                        .amountInWords,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // ── Right: Amount Paid green card ──
                                          SizedBox(
                                            width: 160,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 18,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF72B155),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Amount Paid',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    currencyFormat.format(
                                                      _selectedPayment.amount,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 28),
                                      // ── Paid To vendor block ──
                                      const Text(
                                        'Paid To',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedPayment.vendorName
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ..._selectedPayment.vendorAddress.map(
                                        (line) => Text(
                                          line,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                            fontFamily: 'Inter',
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'GSTIN ${_selectedPayment.vendorGstin}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Inter',
                                          height: 1.5,
                                        ),
                                      ),
                                      if (_selectedPayment.unusedAmount >
                                          0) ...[
                                        const SizedBox(height: 24),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Over payment: ${currencyFormat.format(_selectedPayment.unusedAmount)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CustomPaint(
                                      painter: _DocumentFoldedRibbonPainter(
                                        color: _getStatusColor(
                                          _selectedPayment.status,
                                        ),
                                        label:
                                            _selectedPayment.status
                                                    .toUpperCase() ==
                                                'PAID'
                                            ? 'Paid'
                                            : _selectedPayment.status,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 800,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "PDF Template : ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                _selectedTemplate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared Support UI Components ────────────────────────────────────────────

class _FilterOptionRow extends StatefulWidget {
  final String label;
  final bool isStarred;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _FilterOptionRow({
    required this.label,
    required this.isStarred,
    required this.isSelected,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_FilterOptionRow> createState() => _FilterOptionRowState();
}

class _FilterOptionRowState extends State<_FilterOptionRow> {
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

class _BulkActionMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _BulkActionMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  State<_BulkActionMenuItem> createState() => _BulkActionMenuItemState();
}

class _BulkActionMenuItemState extends State<_BulkActionMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final iconColor = _isHovered ? Colors.white : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: bg,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: iconColor),
                const SizedBox(width: AppTheme.space10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor,
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

class _MainMenuItemWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasSubMenu;
  final bool isActive;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _MainMenuItemWidget({
    required this.icon,
    required this.label,
    this.hasSubMenu = false,
    this.isActive = false,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_MainMenuItemWidget> createState() => _MainMenuItemWidgetState();
}

class _MainMenuItemWidgetState extends State<_MainMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.isActive || _isHovered;
    final bg = isBlue ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = isBlue ? Colors.white : AppTheme.textPrimary;
    final iconColor = isBlue ? Colors.white : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) {
        widget.onHover();
        setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          color: bg,
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.hasSubMenu)
                Icon(LucideIcons.chevronRight, size: 14, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfigurePaymentNumberPreferencesDialog extends StatefulWidget {
  final String currentLocation;
  final String currentSeries;

  const ConfigurePaymentNumberPreferencesDialog({
    required this.currentLocation,
    required this.currentSeries,
  });

  @override
  State<ConfigurePaymentNumberPreferencesDialog> createState() =>
      _ConfigurePaymentNumberPreferencesDialogState();
}

class _ConfigurePaymentNumberPreferencesDialogState
    extends State<ConfigurePaymentNumberPreferencesDialog> {
  bool _autoGenerate = true;
  final TextEditingController _prefixController = TextEditingController(
    text: 'PAY-',
  );
  final TextEditingController _manualPrefixController = TextEditingController(
    text: '',
  );
  final TextEditingController _nextNumberController = TextEditingController(
    text: '98',
  );
  final TextEditingController _manualPaymentNumberController =
      TextEditingController();
  bool _restartFiscalYear = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Container(
        width: 600,
        height: 468.74,
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Payment Number Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location & Associated Series Meta Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Associated Series',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentSeries,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Auto-generating payment numbers can save your time. Would you like to change your current setting?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.4,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Option 1: Auto-generate
                    GestureDetector(
                      onTap: () => setState(() => _autoGenerate = true),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _autoGenerate,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) => setState(() => _autoGenerate = val!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Auto-generate payment numbers',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_autoGenerate) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prefix',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CustomTextField(
                                        controller: _prefixController,
                                        height: 32,
                                        suffixWidget: const Icon(
                                          Icons.add_circle,
                                          color: AppTheme.primaryBlue,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 180,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Number',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CustomTextField(
                                        controller: _nextNumberController,
                                        height: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _restartFiscalYear,
                                    activeColor: AppTheme.primaryBlue,
                                    onChanged: (val) =>
                                        setState(() => _restartFiscalYear = val!),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Restart numbering for payments at the start of each fiscal year.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Option 2: Manual
                    GestureDetector(
                      onTap: () => setState(() => _autoGenerate = false),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: _autoGenerate,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) => setState(() => _autoGenerate = val!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add payment number manually for this payment',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (!_autoGenerate) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Prefix',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomTextField(
                                    controller: _manualPrefixController,
                                    height: 32,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Number',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomTextField(
                                    controller: _manualPaymentNumberController,
                                    height: 32,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // Buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop({
                              'autoGenerate': _autoGenerate,
                              'prefix': _autoGenerate
                                  ? _prefixController.text
                                  : _manualPrefixController.text,
                              'nextNumber': _autoGenerate
                                  ? _nextNumberController.text
                                  : _manualPaymentNumberController.text,
                              'restartFiscalYear': _restartFiscalYear,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: const Color(0xFF374151),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentFoldedRibbonPainter extends CustomPainter {
  final Color color;
  final String label;

  const _DocumentFoldedRibbonPainter({
    required this.color,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bandPath = Path()
      ..moveTo(0, 36)
      ..lineTo(36, 0)
      ..lineTo(76, 0)
      ..lineTo(0, 76)
      ..close();
    canvas.drawPath(bandPath, bandPaint);

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(28, 28);
    canvas.rotate(-0.7853981633974483);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DocumentFoldedRibbonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.label != label;
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<String> selectedPaymentNumbers;
  const _BulkUpdateDialog({required this.selectedPaymentNumbers});

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 640,
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    'Bulk Update Payments Made',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Field to Update', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      initialValue: _selectedField,
                      items: const [
                        DropdownMenuItem(value: 'status', child: Text('Status')),
                        DropdownMenuItem(value: 'notes', child: Text('Notes')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedField = val;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('New Value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _valueController,
                      hintText: 'Enter new value',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedField != null) {
                        Navigator.of(context).pop({
                          'field': _selectedField,
                          'value': _valueController.text,
                        });
                      }
                    },
                    child: const Text('Update'),
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

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

