import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/uppercase_text_formatter.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/associate_templates_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/configure_vendor_portal_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/link_vendor_to_customer_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/clone_vendor_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/dialogs/merge_vendors_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class VendorsOverviewPage extends ConsumerStatefulWidget {
  final String? vendorId;

  const VendorsOverviewPage({super.key, this.vendorId});

  @override
  ConsumerState<VendorsOverviewPage> createState() => _VendorsOverviewPageState();
}

class _VendorsOverviewPageState extends ConsumerState<VendorsOverviewPage> {
  static const List<String> _transactionStatusOptions = <String>[
    'All',
    'Open',
    'Overdue',
    'Unpaid',
    'Partially Paid',
    'Paid',
    'Void',
  ];
  static const List<String> _mailAccountOptions = <String>[
    'Outlook',
    'Zoho Mail',
    'Link with work account',
  ];
  static const List<String> _statementPeriodOptions = <String>[
    'This Month',
    'Last Month',
    'This Quarter',
  ];
  static const List<String> _statementStatusOptions = <String>[
    'All',
    'Outstanding',
  ];
  static const List<String> _statementLocationOptions = <String>[
    'All Locations',
    'ZABNIX PRIVATE LIMITED',
    'SAHAKAR TIRUPUR',
  ];
  static const List<String> _statementCustomizeOptions = <String>[
    'Standard',
    'Change Template',
    'Edit Template',
    'Update Logo & Address',
  ];
  static const List<String> _newTransactionOptions = <String>[
    'Bill',
    'Bill Payment',
    'Expense',
    'Purchase Order',
    'Purchase Receive',
    'Vendor Credit',
  ];

  static const List<String> _bulkActionOptions = <String>[
    'Bulk Update',
    'Send Vendor Statements',
    'Print Vendor Statements',
    'Mark as Active',
    'Mark as Inactive',
    'Merge',
    'Associate Templates',
    'Enable Portal',
    'Disable Portal',
    'Request GST Information',
    'Delete',
  ];

  String _activeTab = 'Overview';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _searchQuery = '';
  String _leftSortByField = 'Name';
  bool _leftSortAscending = true;
  final Set<String> _selectedIds = {};
  bool _addressExpanded = true;
  bool _otherDetailsExpanded = true;
  bool _contactPersonsExpanded = true;
  bool _bankAccountDetailsExpanded = true;
  bool _associateTagsExpanded = true;
  bool _recordInfoExpanded = true;
  bool _isPortalStatusHovered = false;
  bool _isCommentBold = false;
  bool _isCommentItalic = false;
  bool _isCommentUnderlined = false;
  bool _isStatementReportHovered = false;
  bool _isStatementCustomizeOpen = false;
  bool _isAttachmentMenuOpen = false;
  bool _isNewTransactionMenuOpen = false;
  bool _isMoreMenuOpen = false;
  bool _isGoToTransactionsMenuOpen = false;
  bool _showInactiveBanner = false;
  bool _showActiveBanner = false;
  // ignore: unused_field
  String _selectedMailAccountOption = 'Outlook';
  String _selectedStatementPeriod = 'This Month';
  String _selectedStatementStatus = 'All';
  String _selectedStatementLocation = 'All Locations';
  // ignore: unused_field
  String _selectedTransactionDestination = 'Bills';
  String _selectedBulkAction = 'Bulk Update';
  Map<String, dynamic>? _billingAddress;
  Map<String, dynamic>? _shippingAddress;
  final List<_VendorCommentEntry> _comments = [];
  List<PlatformFile> _attachmentFiles = [];
  final Map<String, bool> _vendorInactiveOverrides = <String, bool>{};
  final LayerLink _attachmentMenuLink = LayerLink();
  final LayerLink _newTransactionMenuLink = LayerLink();
  final LayerLink _moreMenuLink = LayerLink();
  final LayerLink _goToTransactionsMenuLink = LayerLink();
  OverlayEntry? _attachmentMenuOverlay;
  OverlayEntry? _newTransactionMenuOverlay;
  OverlayEntry? _moreMenuOverlay;
  OverlayEntry? _goToTransactionsMenuOverlay;

  List<ColumnConfig> _overviewColumns = [
    ColumnConfig(id: 'NAME', label: 'Name', isLocked: true, orderIndex: 0),
    ColumnConfig(
      id: 'VENDOR NUMBER',
      label: 'Vendor Number',
      isLocked: true,
      orderIndex: 1,
    ),
    ColumnConfig(
      id: 'COMPANY NAME',
      label: 'Company Name',
      isLocked: true,
      orderIndex: 2,
    ),
    ColumnConfig(id: 'EMAIL', label: 'Email', orderIndex: 3),
    ColumnConfig(id: 'PHONE', label: 'Phone', orderIndex: 4),
    ColumnConfig(id: 'GST TREATMENT', label: 'GST Treatment', orderIndex: 5),
    ColumnConfig(id: 'PAYABLES', label: 'Payables', orderIndex: 6),
    ColumnConfig(id: 'PAYABLES (BCY)', label: 'Payables (BCY)', orderIndex: 7),
    ColumnConfig(
      id: 'UNUSED CREDITS (BCY)',
      label: 'Unused Credits (BCY)',
      orderIndex: 8,
    ),
    ColumnConfig(id: 'SOURCE', label: 'Source', orderIndex: 9),
    ColumnConfig(
      id: 'SOURCE OF SUPPLY',
      label: 'Source Of Supply',
      isVisible: false,
      orderIndex: 10,
    ),
    ColumnConfig(
      id: 'UNUSED CREDITS',
      label: 'Unused Credits',
      isVisible: false,
      orderIndex: 11,
    ),
    ColumnConfig(id: 'ADGF', label: 'ADGF', isVisible: false, orderIndex: 12),
    ColumnConfig(
      id: 'FIRST NAME',
      label: 'First Name',
      isVisible: false,
      orderIndex: 13,
    ),
    ColumnConfig(
      id: 'GST REGISTRATION NUMBER',
      label: 'GST Registration Number',
      isVisible: false,
      orderIndex: 14,
    ),
    ColumnConfig(
      id: 'LAST NAME',
      label: 'Last Name',
      isVisible: false,
      orderIndex: 15,
    ),
    ColumnConfig(
      id: 'MOBILE PHONE',
      label: 'Mobile Phone',
      isVisible: false,
      orderIndex: 16,
    ),
    ColumnConfig(
      id: 'PAYMENT TERMS',
      label: 'Payment Terms',
      isVisible: false,
      orderIndex: 17,
    ),
    ColumnConfig(
      id: 'STATUS',
      label: 'Status',
      isVisible: false,
      orderIndex: 18,
    ),
    ColumnConfig(
      id: 'WEBSITE',
      label: 'Website',
      isVisible: false,
      orderIndex: 19,
    ),
    ColumnConfig(
      id: 'DEMO ADVACED REPORTING TAG',
      label: 'demo advaced reporting tag',
      isVisible: false,
      orderIndex: 20,
    ),
    ColumnConfig(
      id: 'SCHEDULE',
      label: 'shedule',
      isVisible: false,
      orderIndex: 21,
    ),
  ];

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(vendorProvider);
      if (state.vendors.isEmpty && !state.isLoading) {
        ref.read(vendorProvider.notifier).loadVendors();
      }
    });
  }

  @override
  void dispose() {
    _removeAttachmentMenu();
    _removeNewTransactionMenu();
    _removeMoreMenu();
    _removeGoToTransactionsMenu();
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleAttachmentMenu() {
    if (_isAttachmentMenuOpen) {
      _removeAttachmentMenu();
      return;
    }
    _showAttachmentMenu();
  }

  void _toggleNewTransactionMenu() {
    if (_isNewTransactionMenuOpen) {
      _removeNewTransactionMenu();
      return;
    }
    _showNewTransactionMenu();
  }

  void _toggleMoreMenu() {
    if (_isMoreMenuOpen) {
      _removeMoreMenu();
      return;
    }
    _showMoreMenu();
  }

  void _toggleGoToTransactionsMenu() {
    if (_isGoToTransactionsMenuOpen) {
      _removeGoToTransactionsMenu();
      return;
    }
    _showGoToTransactionsMenu();
  }

  void _showAttachmentMenu() {
    _removeGoToTransactionsMenu();
    _removeMoreMenu();
    _removeNewTransactionMenu();
    _removeAttachmentMenu();
    final overlay = Overlay.of(context);

    _attachmentMenuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeAttachmentMenu,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentMenuLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    transform: Matrix4.rotationZ(0.785398),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: Container(
                      width: 278,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A111827),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(8)),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFEAECEF)),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: _removeAttachmentMenu,
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 15,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFEAECEF)),
                              ),
                            ),
                            child: Text(
                              _attachmentFiles.isEmpty
                                  ? 'No Files Attached'
                                  : '${_attachmentFiles.length} File${_attachmentFiles.length == 1 ? '' : 's'} Attached',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          if (_attachmentFiles.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 152),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFEAECEF)),
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  children: _attachmentFiles
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _AttachmentFileRow(
                                          file: entry.value,
                                          onRemove: () =>
                                              _removeAttachmentFile(entry.key),
                                          formatFileSize:
                                              _formatAttachmentFileSize,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
                            child: Column(
                              children: [
                                _AttachmentUploadCard(
                                  onTap: _pickAttachmentFiles,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You can upload a maximum of 10 files, 10MB each',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

    overlay.insert(_attachmentMenuOverlay!);
    if (mounted) {
      setState(() {
        _isAttachmentMenuOpen = true;
      });
    }
  }

  void _removeAttachmentMenu() {
    _attachmentMenuOverlay?.remove();
    _attachmentMenuOverlay = null;
    if (mounted && _isAttachmentMenuOpen) {
      setState(() {
        _isAttachmentMenuOpen = false;
      });
    }
  }

  void _showNewTransactionMenu() {
    _removeGoToTransactionsMenu();
    _removeMoreMenu();
    _removeAttachmentMenu();
    _removeNewTransactionMenu();
    final overlay = Overlay.of(context);

    _newTransactionMenuOverlay = OverlayEntry(
      builder: (context) {
        int? hoveredIndex;
        return StatefulBuilder(
          builder: (context, setOverlayState) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeNewTransactionMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _newTransactionMenuLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 154,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A111827),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 2, bottom: 8),
                            child: Text(
                              'PURCHASES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          ..._newTransactionOptions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isHovered = hoveredIndex == index;
                            return MouseRegion(
                              onEnter: (_) =>
                                  setOverlayState(() => hoveredIndex = index),
                              onExit: (_) => setOverlayState(() {
                                if (hoveredIndex == index) hoveredIndex = null;
                              }),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _removeNewTransactionMenu();
                                  ZerpaiToast.success(
                                    context,
                                    '$item selected',
                                  );
                                },
                                child: Container(
                                  height: 32,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isHovered
                                        ? const Color(0xFF4A8DF0)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: isHovered
                                          ? Colors.white
                                          : const Color(0xFF4B5563),
                                    ),
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
      },
    );

    overlay.insert(_newTransactionMenuOverlay!);
    if (mounted) {
      setState(() {
        _isNewTransactionMenuOpen = true;
      });
    }
  }

  void _removeNewTransactionMenu() {
    _newTransactionMenuOverlay?.remove();
    _newTransactionMenuOverlay = null;
    if (mounted && _isNewTransactionMenuOpen) {
      setState(() {
        _isNewTransactionMenuOpen = false;
      });
    }
  }

  void _showMoreMenu() {
    _removeGoToTransactionsMenu();
    _removeAttachmentMenu();
    _removeNewTransactionMenu();
    _removeMoreMenu();
    final overlay = Overlay.of(context);
    final selectedVendorId = widget.vendorId;
    if (selectedVendorId == null) return;
    final vendorsState = ref.read(vendorProvider);
    final vendor = vendorsState.vendors.firstWhere(
      (item) => item.id == selectedVendorId,
      orElse: () => vendorsState.vendors.first,
    );
    final isInactive = _isVendorInactive(vendor);
    final moreMenuOptions = <String>[
      'Associate Templates',
      'Configure Vendor Portal',
      'Email Vendor',
      'Add Bank Account',
      'Link to Customer',
      'Clone',
      'Merge Vendors',
      isInactive ? 'Mark as Active' : 'Mark as Inactive',
      'Delete',
    ];

    _moreMenuOverlay = OverlayEntry(
      builder: (context) {
        int? hoveredIndex;
        return StatefulBuilder(
          builder: (context, setOverlayState) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeMoreMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _moreMenuLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 158,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A111827),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: moreMenuOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isHovered = hoveredIndex == index;
                          final showDivider = index == 3;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MouseRegion(
                                onEnter: (_) =>
                                    setOverlayState(() => hoveredIndex = index),
                                onExit: (_) => setOverlayState(() {
                                  if (hoveredIndex == index) hoveredIndex = null;
                                }),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    _removeMoreMenu();
                                    if (item == 'Mark as Inactive') {
                                      _setVendorInactiveState(
                                        vendor,
                                        inactive: true,
                                      );
                                      return;
                                    }
                                    if (item == 'Mark as Active') {
                                      _setVendorInactiveState(
                                        vendor,
                                        inactive: false,
                                      );
                                      return;
                                    }
                                    if (item == 'Delete') {
                                      _deleteVendorFromOverview(vendor);
                                      return;
                                    }
                                    if (item == 'Associate Templates') {
                                      _showAssociateTemplatesDialog();
                                      return;
                                    }
                                    if (item == 'Configure Vendor Portal') {
                                      _showConfigureVendorPortalDialog(vendor);
                                      return;
                                    }
                                    if (item == 'Email Vendor') {
                                      context.go(
                                        '/$_orgId/purchases/vendors/${vendor.id}/email',
                                      );
                                      return;
                                    }
                                    if (item == 'Add Bank Account') {
                                      _showAddBankAccountDialog(vendor);
                                      return;
                                    }
                                    if (item == 'Link to Customer') {
                                      _showLinkToCustomerDialog(vendor);
                                      return;
                                    }
                                    if (item == 'Merge Vendors') {
                                      _showMergeVendorsDialog(vendor);
                                      return;
                                    }
                                    if (item == 'Clone') {
                                      _showCloneDialog(vendor);
                                      return;
                                    }
                                    ZerpaiToast.success(
                                      context,
                                      '$item selected',
                                    );
                                  },
                                  child: Container(
                                    height: 32,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? const Color(0xFF4A8DF0)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: isHovered
                                            ? Colors.white
                                            : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (showDivider)
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(2, 2, 2, 6),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFEAECEF),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_moreMenuOverlay!);
    if (mounted) {
      setState(() {
        _isMoreMenuOpen = true;
      });
    }
  }

  void _removeMoreMenu() {
    _moreMenuOverlay?.remove();
    _moreMenuOverlay = null;
    if (mounted && _isMoreMenuOpen) {
      setState(() {
        _isMoreMenuOpen = false;
      });
    }
  }

  void _showGoToTransactionsMenu() {
    _removeAttachmentMenu();
    _removeNewTransactionMenu();
    _removeMoreMenu();
    _removeGoToTransactionsMenu();
    final overlay = Overlay.of(context);

    const transactionOptions = <String>[
      'Bills',
      'Bill Payments',
      'Expenses',
      'Purchase Orders',
      'Purchase Receives',
      'Vendor Credits',
    ];

    _goToTransactionsMenuOverlay = OverlayEntry(
      builder: (context) {
        int? hoveredIndex;
        return StatefulBuilder(
          builder: (context, setOverlayState) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeGoToTransactionsMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _goToTransactionsMenuLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 8),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 154,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A111827),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: transactionOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isHovered = hoveredIndex == index;
                          return MouseRegion(
                            onEnter: (_) =>
                                setOverlayState(() => hoveredIndex = index),
                            onExit: (_) => setOverlayState(() {
                              if (hoveredIndex == index) hoveredIndex = null;
                            }),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedTransactionDestination = item;
                                });
                                _removeGoToTransactionsMenu();
                              },
                              child: Container(
                                height: 32,
                                margin: const EdgeInsets.only(bottom: 4),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? const Color(0xFF4A8DF0)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isHovered
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_goToTransactionsMenuOverlay!);
    if (mounted) {
      setState(() {
        _isGoToTransactionsMenuOpen = true;
      });
    }
  }

  void _removeGoToTransactionsMenu() {
    _goToTransactionsMenuOverlay?.remove();
    _goToTransactionsMenuOverlay = null;
    if (mounted && _isGoToTransactionsMenuOpen) {
      setState(() {
        _isGoToTransactionsMenuOpen = false;
      });
    }
  }

  Future<void> _pickAttachmentFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final remaining = 10 - _attachmentFiles.length;
    if (remaining <= 0) {
      ZerpaiToast.error(context, 'Maximum 10 files allowed');
      return;
    }

    final List<PlatformFile> validFiles = [];
    for (final file in result.files.take(remaining)) {
      if (file.size <= 10 * 1024 * 1024) {
        validFiles.add(file);
      } else {
        ZerpaiToast.error(context, '${file.name} exceeds 10MB size limit');
      }
    }

    if (validFiles.isEmpty) return;

    setState(() {
      _attachmentFiles = [..._attachmentFiles, ...validFiles];
    });
    _attachmentMenuOverlay?.markNeedsBuild();
  }

  void _removeAttachmentFile(int index) {
    setState(() {
      _attachmentFiles = List<PlatformFile>.from(_attachmentFiles)
        ..removeAt(index);
    });
    _attachmentMenuOverlay?.markNeedsBuild();
  }

  String _formatAttachmentFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool _isVendorInactive(Vendor vendor) {
    return _vendorInactiveOverrides[vendor.id] ?? !vendor.isActive;
  }

  void _showInactiveSuccessBanner() {
    if (!mounted) return;
    setState(() => _showInactiveBanner = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showInactiveBanner = false);
      }
    });
  }

  void _showActiveSuccessBanner() {
    if (!mounted) return;
    setState(() => _showActiveBanner = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showActiveBanner = false);
      }
    });
  }

  Future<void> _setVendorInactiveState(
    Vendor vendor, {
    required bool inactive,
  }) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: inactive ? 'Mark vendor as inactive?' : 'Mark vendor as active?',
      message: inactive
          ? 'This vendor will be marked inactive and the action bar will switch to inactive actions.'
          : 'This vendor will be marked active and the normal action bar will be restored.',
      confirmLabel: inactive ? 'Mark Inactive' : 'Mark Active',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.warning,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _vendorInactiveOverrides[vendor.id] = inactive;
    });

    if (inactive) {
      _showInactiveSuccessBanner();
    } else {
      _showActiveSuccessBanner();
    }
  }

  /// Deletes the currently-open vendor from the backend (Supabase) after a
  /// confirmation dialog, then returns to the vendors list.
  Future<void> _deleteVendorFromOverview(Vendor vendor) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Vendor',
      message: 'Delete ${vendor.displayName}? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(vendorProvider.notifier).deleteVendor(vendor.id);
      if (!mounted) return;
      ZerpaiToast.deleted(context, 'Vendor');
      // The open vendor no longer exists — go back to the vendors list.
      context.go('/$_orgId${AppRoutes.vendors}');
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleBulkAction(String action) async {
    final invoices = ref.read(vendorProvider).vendors;
    final selectedVendors = invoices
        .where((vendor) => _selectedIds.contains(vendor.id))
        .toList();
    if (selectedVendors.isEmpty) return;

    if (action == 'Bulk Update') {
      return;
    }

    if (action == 'Associate Templates') {
      await _showAssociateTagsDialog();
      return;
    }

    if (action == 'Send Vendor Statements' ||
        action == 'Print Vendor Statements' ||
        action == 'Merge' ||
        action == 'Enable Portal' ||
        action == 'Disable Portal' ||
        action == 'Request GST Information') {
      ZerpaiToast.success(context, '$action selected');
      return;
    }

    if (action == 'Mark as Active') {
      final confirmed = await showZerpaiConfirmationDialog(
        context,
        title: 'Mark selected vendors as active?',
        message:
            'Mark ${selectedVendors.length} selected vendor(s) as active?',
        confirmLabel: 'Mark Active',
        cancelLabel: 'Cancel',
        variant: ZerpaiConfirmationVariant.warning,
      );
      if (!confirmed || !mounted) return;
      setState(() {
        for (final vendor in selectedVendors) {
          _vendorInactiveOverrides[vendor.id] = false;
        }
      });
      _showActiveSuccessBanner();
      return;
    }

    if (action == 'Mark as Inactive') {
      final confirmed = await showZerpaiConfirmationDialog(
        context,
        title: 'Mark selected vendors as inactive?',
        message:
            'Mark ${selectedVendors.length} selected vendor(s) as inactive?',
        confirmLabel: 'Mark Inactive',
        cancelLabel: 'Cancel',
        variant: ZerpaiConfirmationVariant.warning,
      );
      if (!confirmed || !mounted) return;
      setState(() {
        for (final vendor in selectedVendors) {
          _vendorInactiveOverrides[vendor.id] = true;
        }
      });
      _showInactiveSuccessBanner();
      return;
    }

    if (action == 'Delete') {
      final confirmed = await showZerpaiConfirmationDialog(
        context,
        title: 'Delete Selected',
        message:
            'Delete ${selectedVendors.length} selected vendor(s)? This cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        variant: ZerpaiConfirmationVariant.danger,
      );
      if (!confirmed || !mounted) return;
      for (final vendor in selectedVendors) {
        ref.read(vendorProvider.notifier).deleteVendor(vendor.id);
      }
      setState(() {
        _selectedIds.clear();
      });
      ZerpaiToast.deleted(context, 'Selected vendors');
    }
  }

  Future<void> _showAddressDialog({
    required bool isBilling,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address dialog',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 128),
            child: _VendorOverviewAddressDialog(
              title: isBilling ? 'Billing Address' : 'Shipping Address',
              initialAddress: isBilling ? _billingAddress : _shippingAddress,
              onSave: (address) {
                setState(() {
                  if (isBilling) {
                    _billingAddress = address;
                  } else {
                    _shippingAddress = address;
                  }
                });
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showPortalAccessDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Configure portal access',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: _VendorPortalAccessDialog(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showAddContactPersonDialog() async {
    await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Contact Person'),
        content: const Text('Contact person form coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _showAddBankAccountDialog(Vendor vendor) async {
    final added = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add bank account details',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: _VendorBankAccountDialog(
              vendorId: vendor.id,
              accountHolderName: vendor.displayName,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (added == true && mounted) {
      ref.read(vendorProvider.notifier).loadVendors();
    }
  }

  Future<void> _showAssociateTemplatesDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const AssociateTemplatesDialog(),
    );
  }

  Future<void> _showConfigureVendorPortalDialog(Vendor vendor) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfigureVendorPortalDialog(
        vendorId: vendor.id,
        fallbackVendor: vendor,
      ),
    );
  }

  Future<void> _showLinkToCustomerDialog(Vendor vendor) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          LinkVendorToCustomerDialog(vendorName: vendor.displayName),
    );
  }

  Future<void> _showMergeVendorsDialog(Vendor vendor) async {
    final destinationVendor = await showDialog<Vendor?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => MergeVendorsDialog(currentVendor: vendor),
    );

    if (destinationVendor == null || !mounted) return;

    setState(() {
      _vendorInactiveOverrides[vendor.id] = true;
    });

    _showInactiveSuccessBanner();

    ZerpaiToast.success(
      context,
      'Transactions of ${vendor.displayName} transferred to ${destinationVendor.displayName} successfully.',
    );
  }

  Future<void> _showCloneDialog(Vendor vendor) async {
    final type = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const CloneVendorDialog(),
    );

    if (type == null || !mounted) return;

    if (type == 'Vendor') {
      context.go('/$_orgId/purchases/vendors/create?cloneId=${vendor.id}');
    } else {
      context.go('/$_orgId/sales/customers/create?cloneId=${vendor.id}');
    }
  }

  Future<void> _showAssociateTagsDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Associate tags',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: _VendorAssociateTagsDialog(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showOverviewCustomizeColumnsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => ColumnCustomizerDialog(
        columns: _overviewColumns
            .map((c) => ColumnConfig.fromJson(c.toJson()))
            .toList(),
        onSave: (newColumns) {
          Navigator.pop(ctx, newColumns);
        },
      ),
    ).then((dynamic result) {
      if (result != null && result is List<ColumnConfig> && mounted) {
        setState(() => _overviewColumns = result);
      }
    });
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(
        0,
        _VendorCommentEntry(
          author: 'zabnixprivatelimited',
          timestamp: DateTime.now(),
          message: text,
          isBold: _isCommentBold,
          isItalic: _isCommentItalic,
          isUnderlined: _isCommentUnderlined,
        ),
      );
      _commentController.clear();
    });
  }

  void _deleteComment(_VendorCommentEntry entry) {
    setState(() {
      _comments.remove(entry);
    });
  }

  int _compareOverviewVendors(Vendor a, Vendor b) {
    final emailA = (a.email ?? '').toLowerCase();
    final emailB = (b.email ?? '').toLowerCase();
    final field = _leftSortByField;
    int compare;
    switch (field) {
      case 'Vendor Number':
        compare = (a.vendorNumber ?? '').toLowerCase().compareTo((b.vendorNumber ?? '').toLowerCase());
        break;
      case 'Company Name':
        compare = (a.companyName ?? '').toLowerCase().compareTo((b.companyName ?? '').toLowerCase());
        break;
      case 'Email':
        compare = emailA.compareTo(emailB);
        break;
      case 'Phone':
        compare = 0;
        break;
      case 'GST Treatment':
        compare = (a.gstTreatment ?? '').compareTo(b.gstTreatment ?? '');
        break;
      case 'Payables':
      case 'Payables (BCY)':
      case 'Unused Credits':
      case 'Unused Credits (BCY)':
        compare = 0;
        break;
      case 'Status':
        compare = a.isActive.toString().compareTo(b.isActive.toString());
        break;
      case 'Name':
      default:
        compare = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    }
    return _leftSortAscending ? compare : -compare;
  }

  String _formatAddressSummary(Map<String, dynamic> address) {
    final parts = <String>[
      (address['street1'] ?? '').toString().trim(),
      (address['street2'] ?? '').toString().trim(),
      (address['city'] ?? '').toString().trim(),
      (address['stateName'] ?? '').toString().trim(),
      (address['zip'] ?? '').toString().trim(),
      (address['countryName'] ?? '').toString().trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Address saved' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorProvider);

    if (state.isLoading && state.vendors.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: CustomerDetailSkeleton(),
      );
    }

    final vendors = state.vendors;

    // Search filter
    final filteredVendors = vendors.where((v) {
      if (_searchQuery.isEmpty) return true;
      return v.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (v.vendorNumber ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (v.companyName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (v.email ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    filteredVendors.sort(_compareOverviewVendors);

    // Selected vendor details
    final currentId = widget.vendorId ?? (filteredVendors.isNotEmpty ? filteredVendors.first.id : '');
    final selectedVendor = filteredVendors.isNotEmpty
        ? vendors.firstWhere(
            (v) => v.id == currentId,
            orElse: () => filteredVendors.first,
          )
        : null;

    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SplitListDetailLayout(
            leftWidth: 320,
            leftHeader: _buildLeftHeader(),
            leftBody: _buildLeftList(filteredVendors, currentId, currencyFormat),
            rightHeader: selectedVendor != null ? _buildRightHeader(selectedVendor) : const SizedBox.shrink(),
            rightBody: selectedVendor != null ? _buildRightBody(selectedVendor, currencyFormat) : const Center(child: Text('Select a vendor to view details.')),
          ),
          if (_showInactiveBanner)
            _buildStatusSuccessBanner(
              message: 'The selected contacts have been marked as inactive.',
            ),
          if (_showActiveBanner)
            _buildStatusSuccessBanner(
              message: 'The selected contacts have been marked as active.',
            ),
        ],
      ),
    );
  }

  // ── Left Sidebar Widgets ───────────────────────────────────────────────────

  Widget _buildLeftHeader() {
    if (_selectedIds.isNotEmpty) {
      return Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.check,
                  size: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 118,
                child: FormDropdown<String>(
                  value: _selectedBulkAction,
                  items: _bulkActionOptions,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedBulkAction = value;
                    });
                    await _handleBulkAction(value);
                  },
                  displayStringForValue: (_) => 'Bulk Actions',
                  showSearch: false,
                  height: 30,
                  itemHeight: 34,
                  menuWidth: 192,
                  menuMaxHeight: 372,
                  borderRadius: BorderRadius.circular(6),
                  fillColor: const Color(0xFFF5F5F5),
                  border: Border.all(color: const Color(0xFFD8E0EA)),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                  itemBuilder: (item, isSelected, isHovered) {
                    final isActive = isHovered || isSelected;
                    return SizedBox(
                      height: 34,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 20,
                color: const Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_selectedIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Selected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _selectedIds.clear()),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'All Vendors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
          const Spacer(),
          // Plus New Button
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF22A95E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(28, 28),
            ),
            onPressed: () => context.go('/$_orgId${AppRoutes.vendorsCreate}'),
          ),
          const SizedBox(width: 8),
          _OverviewListOptionsMenu(
            sortByField: _leftSortByField,
            sortAscending: _leftSortAscending,
            onSortChanged: (field, asc) {
              setState(() {
                _leftSortByField = field;
                _leftSortAscending = asc;
              });
            },
            onRefresh: () {
              ref.read(vendorProvider.notifier).loadVendors();
            },
            onResetColumnWidths: () {
              ZerpaiToast.success(context, 'Column widths reset');
            },
            onCustomizeColumns: _showOverviewCustomizeColumnsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSuccessBanner({required String message}) {
    return Positioned(
      top: 4,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -56, end: 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Container(
              width: 360,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22A95E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftList(
    List<Vendor> list,
    String selectedId,
    NumberFormat currency,
  ) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, idx) {
              final v = list[idx];
              final isSelected = v.id == selectedId;
              final isInactive = _isVendorInactive(v);

              return Material(
                color: isSelected ? const Color(0xFFF1F1FA) : Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final detailPath = AppRoutes.vendorsDetail.replaceAll(':id', v.id);
                    context.go('/$_orgId$detailPath');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              checkboxTheme: CheckboxThemeData(
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                fillColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const Color(0xFF2563EB);
                                  }
                                  return Colors.white;
                                }),
                                checkColor: const WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _selectedIds.contains(v.id),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(v.id);
                                  } else {
                                    _selectedIds.remove(v.id);
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Vendor Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                v.email ?? '--',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isInactive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Right Detail Pane Widgets ──────────────────────────────────────────────

  Widget _buildRightHeader(Vendor vendor) {
    const headerActionBorder = Color(0xFFD9E1EC);
    const headerActionRadius = 6.0;
    const headerActionHeight = 32.32;
    const editButtonWidth = 44.93;
    const markActiveButtonWidth = 100.0;
    const pinButtonWidth = 35.28;
    const deleteButtonWidth = 58.0;
    const newTransactionButtonWidth = 135.18;
    const moreButtonWidth = 63.19;
    final isInactive = _isVendorInactive(vendor);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              vendor.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isInactive) ...[
            // Edit
            OutlinedButton(
              onPressed: () =>
                  context.go('/$_orgId/purchases/vendors/${vendor.id}/edit'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                padding: EdgeInsets.zero,
                minimumSize: const Size(editButtonWidth, headerActionHeight),
                maximumSize: const Size(editButtonWidth, headerActionHeight),
                fixedSize: const Size(editButtonWidth, headerActionHeight),
                side: const BorderSide(color: headerActionBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(headerActionRadius),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => _setVendorInactiveState(vendor, inactive: false),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                padding: EdgeInsets.zero,
                minimumSize:
                    const Size(markActiveButtonWidth, headerActionHeight),
                maximumSize:
                    const Size(markActiveButtonWidth, headerActionHeight),
                fixedSize:
                    const Size(markActiveButtonWidth, headerActionHeight),
                side: const BorderSide(color: headerActionBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(headerActionRadius),
                ),
              ),
              child: const Text(
                'Mark as Active',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Attach paperclip
          CompositedTransformTarget(
            link: _attachmentMenuLink,
            child: IconButton(
              icon: const Icon(
                LucideIcons.paperclip,
                size: 16,
                color: AppTheme.textPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                side: const BorderSide(color: headerActionBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(headerActionRadius),
                ),
                padding: EdgeInsets.zero,
                minimumSize: const Size(pinButtonWidth, headerActionHeight),
                maximumSize: const Size(pinButtonWidth, headerActionHeight),
                fixedSize: const Size(pinButtonWidth, headerActionHeight),
              ),
              onPressed: _toggleAttachmentMenu,
            ),
          ),
          if (!isInactive) ...[
            const SizedBox(width: 8),
            // New Transaction Dropdown
            CompositedTransformTarget(
              link: _newTransactionMenuLink,
              child: ElevatedButton(
                onPressed: _toggleNewTransactionMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22B573),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize:
                      const Size(newTransactionButtonWidth, headerActionHeight),
                  maximumSize:
                      const Size(newTransactionButtonWidth, headerActionHeight),
                  fixedSize:
                      const Size(newTransactionButtonWidth, headerActionHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(headerActionRadius),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New Transaction',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // More Outlined Dropdown
            CompositedTransformTarget(
              link: _moreMenuLink,
              child: OutlinedButton(
                onPressed: _toggleMoreMenu,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(moreButtonWidth, headerActionHeight),
                  maximumSize: const Size(moreButtonWidth, headerActionHeight),
                  fixedSize: const Size(moreButtonWidth, headerActionHeight),
                  side: const BorderSide(color: headerActionBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(headerActionRadius),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => ZerpaiToast.success(context, 'Delete selected'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                padding: EdgeInsets.zero,
                minimumSize: const Size(deleteButtonWidth, headerActionHeight),
                maximumSize: const Size(deleteButtonWidth, headerActionHeight),
                fixedSize: const Size(deleteButtonWidth, headerActionHeight),
                side: const BorderSide(color: headerActionBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(headerActionRadius),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Close button
          IconButton(
            icon: const Icon(
              LucideIcons.x,
              size: 20,
              color: Color(0xFF374151),
              weight: 2.4,
            ),
            onPressed: () => context.go('/$_orgId${AppRoutes.vendors}'),
          ),
        ],
      ),
    );
  }

  Widget _buildRightBody(Vendor vendor, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildTab('Overview'),
              const SizedBox(width: 24),
              _buildTab('Comments'),
              const SizedBox(width: 24),
              _buildTab('Transactions'),
              const SizedBox(width: 24),
              _buildTab('Mails'),
              const SizedBox(width: 24),
              _buildTab('Statement'),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: SingleChildScrollView(
            padding: _activeTab == 'Overview'
                ? EdgeInsets.zero
                : const EdgeInsets.all(24),
            child: _activeTab == 'Overview'
                ? _buildOverviewTabContent(vendor, currency)
                : _activeTab == 'Comments'
                    ? _buildCommentsTabContent()
                    : _activeTab == 'Transactions'
                        ? _buildTransactionsTabContent()
                        : _activeTab == 'Mails'
                            ? _buildMailsTabContent()
                            : _activeTab == 'Statement'
                                ? _buildStatementTabContent(vendor)
                        : Center(child: Text('$_activeTab tab content')),
          ),
        ),
      ],
    );
  }

  Widget _buildMailsTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EAF3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    const Text(
                      'System Mails',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 186,
                      child: FormDropdown<String>(
                        value: 'Outlook',
                        items: _mailAccountOptions,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMailAccountOption = value;
                          });
                        },
                        displayStringForValue: (value) => 'Link Email account',
                        showSearch: false,
                        menuWidth: 171.46,
                        itemHeight: 38.716,
                        menuMaxHeight: 118.15,
                        maxVisibleItems: _mailAccountOptions.length,
                        iconSize: 15,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                        prefixWidget: const Icon(
                          LucideIcons.mail,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        itemBuilder: (item, isSelected, isHovered) {
                          final isActive = isHovered;
                          return SizedBox(
                            height: 38.716,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
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
              const Divider(height: 1, color: Color(0xFFE9EDF5)),
              Container(
                height: 138,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'No emails sent.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111827),
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
  }

  Widget _buildStatementTabContent(Vendor vendor) {
    const borderColor = Color(0xFFD9E0EA);
    const sheetShadow = Color(0x14000000);
    const currencyGlyph = '\u20B9';
    const currencyTextStyle = TextStyle(
      fontSize: 11.5,
      color: Color(0xFF111827),
      fontFamilyFallback: <String>['Roboto', 'Noto Sans', 'Arial'],
    );
    const currencyTextStyleBold = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827),
      fontFamilyFallback: <String>['Roboto', 'Noto Sans', 'Arial'],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildStatementFilterDropdown(
                width: 180,
                value: _selectedStatementPeriod,
                items: _statementPeriodOptions,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatementPeriod = value);
                },
                prefixIcon: LucideIcons.calendar,
                menuMaxHeight: 342,
              ),
              const SizedBox(width: 12),
              _buildStatementFilterDropdown(
                width: 116,
                value: _selectedStatementStatus,
                items: _statementStatusOptions,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatementStatus = value);
                },
                labelBuilder: (value) => 'Filter By: $value',
                menuMaxHeight: 78,
              ),
              const SizedBox(width: 12),
              _buildStatementFilterDropdown(
                width: 182,
                value: _selectedStatementLocation,
                items: _statementLocationOptions,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatementLocation = value);
                },
                labelBuilder: (value) => 'Location: $value',
                menuMaxHeight: 112,
              ),
              const Spacer(),
              _buildStatementIconButton(
                LucideIcons.printer,
                tooltipMessage: 'Print',
              ),
              const SizedBox(width: 10),
              _buildStatementIconButton(
                LucideIcons.save,
                tooltipMessage: 'PDF',
              ),
              const SizedBox(width: 10),
              _buildStatementIconButton(
                LucideIcons.folder,
                tooltipMessage: 'XLS',
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF22B573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.mail, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Send Email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Text(
            'Vendor Statement For ${vendor.displayName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'From 01-06-2026 To 30-06-2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 42),
          Center(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isStatementReportHovered = true),
              onExit: (_) {
                if (_isStatementCustomizeOpen) return;
                setState(() => _isStatementReportHovered = false);
              },
              child: Container(
                width: 895,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: sheetShadow,
                      blurRadius: 14,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(60, 46, 44, 68),
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
                                  Container(
                                    width: 270,
                                    height: 106,
                                    color: const Color(0xFF111111),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Company Logo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 58),
                                  const Text(
                                    'To',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 240,
                                    child: Text(
                                      vendor.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 290,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: const [
                                  Text(
                                    'ZABNIX PRIVATE LIMITED',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia\nGSTIN 32AACCZ4912F1ZL\n8086355500\nzabnixprivatelimited@gmail.com',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.6,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 44),
                                  Text(
                                    'Statement of Accounts',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Divider(
                                    thickness: 1,
                                    height: 1,
                                    color: Color(0xFF111827),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '01-06-2026 To 30-06-2026',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Divider(
                                    thickness: 1,
                                    height: 1,
                                    color: Color(0xFF111827),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 310,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  color: const Color(0xFFE5E7EB),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  child: const Text(
                                    'Account Summary',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                _buildStatementSummaryRow(
                                  'Opening Balance',
                                  '$currencyGlyph -11,90,500.00',
                                  valueStyle: currencyTextStyle,
                                ),
                                _buildStatementSummaryRow(
                                  'Billed Amount',
                                  '$currencyGlyph 2,100.00',
                                  valueStyle: currencyTextStyle,
                                ),
                                _buildStatementSummaryRow(
                                  'Amount Paid',
                                  '$currencyGlyph 0.00',
                                  valueStyle: currencyTextStyle,
                                ),
                                _buildStatementSummaryRow(
                                  'Balance Due',
                                  '$currencyGlyph -11,88,400.00',
                                  valueStyle: currencyTextStyle,
                                  addBottomBorder: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 42),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.1),
                            1: FlexColumnWidth(1.2),
                            2: FlexColumnWidth(2.4),
                            3: FlexColumnWidth(1.0),
                            4: FlexColumnWidth(1.1),
                            5: FlexColumnWidth(1.3),
                          },
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: Color(0xFF3C3C37),
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Transactions',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Amount',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Payments',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Balance',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildStatementTableRow(
                              date: '01-06-2026',
                              transaction: '***Opening\nBalance***',
                              details: '',
                              amount: '-11,90,500.00',
                              payments: '',
                              balance: '-11,90,500.00',
                            ),
                            _buildStatementTableRow(
                              date: '15-06-2026',
                              transaction: 'Bill',
                              details: 'PO-00046\n32 - due on 15-06-2026',
                              amount: '2,100.00',
                              payments: '',
                              balance: '-11,88,400.00',
                              shaded: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Text(
                              'Balance Due      $currencyGlyph -11,88,400.00',
                              style: currencyTextStyleBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                    if (_isStatementReportHovered || _isStatementCustomizeOpen)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildStatementCustomizeDropdown(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildStatementFilterDropdown({
    required double width,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? prefixIcon,
    String Function(String value)? labelBuilder,
    double? menuMaxHeight,
  }) {
    return SizedBox(
      width: width,
      child: FormDropdown<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        displayStringForValue: (item) => labelBuilder?.call(item) ?? item,
        showSearch: false,
        menuWidth: width,
        height: 36,
        itemHeight: 34,
        menuMaxHeight: menuMaxHeight,
        borderRadius: BorderRadius.circular(6),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF374151),
        ),
        prefixWidget: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                size: 16,
                color: const Color(0xFF111827),
              ),
        itemBuilder: (item, isSelected, isHovered) {
          final isActive = isHovered;
          return SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isActive ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatementCustomizeDropdown() {
    return SizedBox(
      width: 142,
      child: FormDropdown<String>(
        value: 'Standard',
        items: _statementCustomizeOptions,
        onChanged: (_) {},
        displayStringForValue: (_) => 'Customize',
        showSearch: false,
        menuWidth: 160,
        itemHeight: 38,
        menuMaxHeight: 154,
        forceDownward: true,
        hideBorderDefault: true,
        border: Border.all(color: Colors.transparent),
        fillColor: const Color(0xFF22B573),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        height: 32,
        prefixWidget: const Icon(
          LucideIcons.settings,
          size: 13,
          color: Colors.white,
        ),
        iconSize: 13,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        itemBuilder: (item, isSelected, isHovered) {
          final isActive = isHovered;
          return Container(
            height: 38,
            color: isActive ? const Color(0xFF4A8DF0) : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? Colors.white
                        : isSelected
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatementIconButton(
    IconData icon, {
    required String tooltipMessage,
  }) {
    return ZTooltip(
      message: tooltipMessage,
      direction: ZTooltipDirection.bottom,
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D0DE)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF111827)),
      ),
    );
  }

  Widget _buildStatementSummaryRow(
    String label,
    String value, {
    bool addBottomBorder = false,
    TextStyle? valueStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: addBottomBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFF111827)),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF111827),
                ),
          ),
        ],
      ),
    );
  }

  TableRow _buildStatementTableRow({
    required String date,
    required String transaction,
    required String details,
    required String amount,
    required String payments,
    required String balance,
    bool shaded = false,
  }) {
    const textStyle = TextStyle(
      fontSize: 11.5,
      height: 1.45,
      color: Color(0xFF111827),
    );
    const currencyStyle = TextStyle(
      fontSize: 11.5,
      height: 1.45,
      color: Color(0xFF111827),
      fontFamilyFallback: <String>['Roboto', 'Noto Sans', 'Arial'],
    );

    return TableRow(
      decoration: BoxDecoration(
        color: shaded ? const Color(0xFFF4F4F2) : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(date, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(transaction, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(details, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: currencyStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            payments,
            textAlign: TextAlign.right,
            style: currencyStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            balance,
            textAlign: TextAlign.right,
            style: currencyStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Go to transactions dropdown
          CompositedTransformTarget(
            link: _goToTransactionsMenuLink,
            child: InkWell(
              onTap: _toggleGoToTransactionsMenu,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Go to transactions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 14,
                      color: Color(0xFF111827),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Sections List
          _buildTransactionSection('Bills', hasData: true),
          _buildTransactionSection('Bill Payments', hasData: true),
          _buildTransactionSection('Expenses', hasData: true),
          _buildTransactionSection('Purchase Orders', hasData: true),
          _buildTransactionSection('Purchase Receives', hasData: true),
          _buildTransactionSection('Vendor Credits', hasData: true),
        ],
      ),
    );
  }

  // Active expanded sections state map
  final Map<String, bool> _expandedSections = {
    'Bills': true,
    'Bill Payments': true,
  };
  final Map<String, int> _transactionPageIndexes = <String, int>{};
  final Map<String, String> _transactionStatusFilters = <String, String>{};
  final Map<String, int> _vendorSectionSortCol = {};
  final Map<String, bool> _vendorSectionSortAsc = {};

  String _transactionStatusFor(String section) =>
      _transactionStatusFilters[section] ?? _transactionStatusOptions.first;

  double _parseCurrencyVal(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  List<_VendorTransactionRow> _transactionRowsFor(
    String section, {
    required bool hasData,
  }) {
    if (!hasData) return const <_VendorTransactionRow>[];

    const allRows = <String, List<_VendorTransactionRow>>{
      'Bills': <_VendorTransactionRow>[
        _VendorTransactionRow(
          date: '15-06-2026',
          location: 'ZABNIX PRIVATE LIMITED',
          billNo: '32',
          orderNumber: 'PO-00046',
          vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
          amount: 'Rs. 2,100.00',
          balanceDue: 'Rs. 2,100.00',
          status: 'Overdue',
          statusColor: Color(0xFFEF4444),
        ),
        _VendorTransactionRow(
          date: '18-06-2026',
          location: 'ZABNIX PRIVATE LIMITED',
          billNo: '33',
          orderNumber: 'PO-00047',
          vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
          amount: 'Rs. 1,480.00',
          balanceDue: 'Rs. 1,480.00',
          status: 'Open',
          statusColor: Color(0xFF2563EB),
        ),
      ],
      'Bill Payments': <_VendorTransactionRow>[
        _VendorTransactionRow(
          date: '19-06-2026',
          location: 'ZABNIX PRIVATE LIMITED',
          billNo: 'BP-0001',
          orderNumber: 'PO-00046',
          vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
          amount: 'Rs. 620.00',
          balanceDue: 'Rs. 0.00',
          status: 'Paid',
          statusColor: Color(0xFF16A34A),
        ),
      ],
      'Expenses': <_VendorTransactionRow>[],
      'Purchase Orders': <_VendorTransactionRow>[],
      'Purchase Receives': <_VendorTransactionRow>[],
      'Vendor Credits': <_VendorTransactionRow>[],
    };

    List<_VendorTransactionRow> rows = List.from(allRows[section] ?? const <_VendorTransactionRow>[]);
    final selectedStatus = _transactionStatusFor(section);
    if (selectedStatus != 'All') {
      rows = rows.where((row) => row.status == selectedStatus).toList();
    }

    final sortCol = _vendorSectionSortCol[section];
    final sortAsc = _vendorSectionSortAsc[section] ?? true;

    if (sortCol != null) {
      rows.sort((a, b) {
        int cmp = 0;
        switch (sortCol) {
          case 0:
            cmp = a.date.compareTo(b.date);
            break;
          case 1:
            cmp = a.location.compareTo(b.location);
            break;
          case 2:
            cmp = a.billNo.compareTo(b.billNo);
            break;
          case 3:
            cmp = a.orderNumber.compareTo(b.orderNumber);
            break;
          case 4:
            cmp = a.vendorName.compareTo(b.vendorName);
            break;
          case 5:
            cmp = _parseCurrencyVal(a.amount).compareTo(_parseCurrencyVal(b.amount));
            break;
          case 6:
            cmp = _parseCurrencyVal(a.balanceDue).compareTo(_parseCurrencyVal(b.balanceDue));
            break;
          case 7:
            cmp = a.status.compareTo(b.status);
            break;
        }
        return sortAsc ? cmp : -cmp;
      });
    }

    return rows;
  }

  Widget _buildTransactionStatusDropdown(String section) {
    final selectedStatus = _transactionStatusFor(section);

    return PopupMenuButton<String>(
      initialValue: selectedStatus,
      onSelected: (val) {
        setState(() {
          _transactionStatusFilters[section] = val;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.filter,
              size: 13,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              'Status: $selectedStatus',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              LucideIcons.chevronDown,
              size: 13,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return _transactionStatusOptions.map((status) {
          return PopupMenuItem<String>(
            value: status,
            height: 32,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: selectedStatus == status
                    ? AppTheme.primaryBlue
                    : const Color(0xFF374151),
                fontWeight: selectedStatus == status
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildVendorTableHeader(
    String section,
    List<String> titles,
    List<int> flexes,
  ) {
    final currentSortCol = _vendorSectionSortCol[section];
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(titles.length, (i) {
          final isSorted = currentSortCol == i;
          return Expanded(
            flex: flexes[i],
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_vendorSectionSortCol[section] == i) {
                    _vendorSectionSortAsc[section] =
                        !(_vendorSectionSortAsc[section] ?? true);
                  } else {
                    _vendorSectionSortCol[section] = i;
                    _vendorSectionSortAsc[section] = true;
                  }
                });
              },
              child: Center(
                child: Text(
                  titles[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSorted
                        ? AppTheme.primaryBlue
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<String> _getVendorRowColValues(String section, _VendorTransactionRow row) {
    switch (section) {
      case 'Bills':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.vendorName,
          row.amount,
          row.balanceDue,
          row.status,
        ];
      case 'Bill Payments':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.vendorName,
          row.amount,
          row.balanceDue,
          row.status,
        ];
      case 'Expenses':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.vendorName,
          row.amount,
          row.status,
        ];
      case 'Purchase Orders':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.amount,
          row.status,
        ];
      case 'Purchase Receives':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.amount,
          row.status,
        ];
      case 'Vendor Credits':
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.balanceDue,
          row.amount,
          row.status,
        ];
      default:
        return [
          row.date,
          row.location,
          row.billNo,
          row.orderNumber,
          row.amount,
          row.status,
        ];
    }
  }

  Widget _buildVendorStatusBadge(String status) {
    Color bg = const Color(0xFFF3F4F6);
    Color fg = const Color(0xFF374151);

    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'overdue':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case 'open':
      case 'active':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'partially paid':
      case 'partially_paid':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'void':
      case 'draft':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildVendorTableContent(
    String section,
    List<_VendorTransactionRow> items,
  ) {
    List<String> titles;
    List<int> flexes;

    switch (section) {
      case 'Bills':
        titles = [
          'DATE',
          'LOCATION',
          'BILL#',
          'ORDER NUMBER',
          'VENDOR NAME',
          'AMOUNT',
          'BALANCE DUE',
          'STATUS',
        ];
        flexes = [2, 3, 2, 2, 3, 2, 2, 2];
        break;
      case 'Bill Payments':
        titles = [
          'DATE',
          'LOCATION',
          'BILL#',
          'ORDER NUMBER',
          'VENDOR NAME',
          'AMOUNT',
          'BALANCE DUE',
          'STATUS',
        ];
        flexes = [2, 3, 2, 2, 3, 2, 2, 2];
        break;
      case 'Expenses':
        titles = [
          'DATE',
          'LOCATION',
          'EXPENSE#',
          'REFERENCE NUMBER',
          'VENDOR NAME',
          'AMOUNT',
          'STATUS',
        ];
        flexes = [2, 3, 2, 2, 3, 2, 2];
        break;
      case 'Purchase Orders':
        titles = [
          'DATE',
          'LOCATION',
          'PURCHASE ORDER#',
          'REFERENCE NUMBER',
          'AMOUNT',
          'STATUS',
        ];
        flexes = [2, 3, 3, 2, 2, 2];
        break;
      case 'Purchase Receives':
        titles = [
          'DATE',
          'LOCATION',
          'PURCHASE RECEIVE#',
          'ORDER NUMBER',
          'AMOUNT',
          'STATUS',
        ];
        flexes = [2, 3, 3, 2, 2, 2];
        break;
      case 'Vendor Credits':
        titles = [
          'CREDIT DATE',
          'LOCATION',
          'VENDOR CREDIT#',
          'REFERENCE NUMBER',
          'BALANCE',
          'AMOUNT',
          'STATUS',
        ];
        flexes = [2, 3, 3, 2, 2, 2, 2];
        break;
      default:
        titles = [
          'DATE',
          'LOCATION',
          'NUMBER',
          'REFERENCE NUMBER',
          'AMOUNT',
          'STATUS',
        ];
        flexes = [2, 3, 3, 2, 2, 2];
    }

    return Column(
      children: [
        _buildVendorTableHeader(section, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${section.toLowerCase()} found for this vendor.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((row) {
            final colValues = _getVendorRowColValues(section, row);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: List.generate(titles.length, (idx) {
                  final String val =
                      idx < colValues.length ? colValues[idx] : '-';
                  final bool isStatusCol = idx == titles.length - 1;
                  final bool isNumberCol = (section == 'Bills' && idx == 2) ||
                      (section == 'Bill Payments' && idx == 2) ||
                      (section == 'Expenses' && idx == 2) ||
                      (section == 'Purchase Orders' && idx == 2) ||
                      (section == 'Purchase Receives' && idx == 2) ||
                      (section == 'Vendor Credits' && idx == 2);

                  Widget content;
                  if (isStatusCol) {
                    content = _buildVendorStatusBadge(val);
                  } else if (isNumberCol) {
                    content = Text(
                      val,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    );
                  } else {
                    content = Text(
                      val,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    );
                  }

                  return Expanded(
                    flex: flexes[idx],
                    child: Center(child: content),
                  );
                }),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTransactionSection(String section, {bool hasData = false}) {
    final isExpanded = _expandedSections[section] ?? false;
    final transactionRows = _transactionRowsFor(section, hasData: hasData);
    final transactionCount = transactionRows.length;
    final currentPageIndex = (_transactionPageIndexes[section] ?? 0).clamp(
      0,
      transactionCount == 0 ? 0 : transactionCount - 1,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedSections[section] = !isExpanded;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      section,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    if (isExpanded) ...[
                      _buildTransactionStatusDropdown(section),
                      const SizedBox(width: 10),
                    ],
                    InkWell(
                      onTap: () {
                        const orgId = '00000000-0000-0000-0000-000000000002';
                        if (section == 'Bills') {
                          context.go('/$orgId/purchases/bills/create');
                        } else if (section == 'Bill Payments') {
                          context.go('/$orgId/purchases/payments-made/create');
                        } else if (section == 'Expenses') {
                          context.go('/$orgId/purchases/expenses/create');
                        } else if (section == 'Purchase Orders') {
                          context.go('/$orgId/purchases/orders/create');
                        } else if (section == 'Purchase Receives') {
                          context.go('/$orgId/purchases/receives/create');
                        } else if (section == 'Vendor Credits') {
                          context.go('/$orgId/purchases/vendor-credits/create');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 13,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _buildVendorTableContent(section, transactionRows),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Footer pagination bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Total Count: $transactionCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: currentPageIndex > 0
                              ? () => setState(
                                    () => _transactionPageIndexes[section] =
                                        currentPageIndex - 1,
                                  )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              size: 14,
                              color: currentPageIndex > 0
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            transactionCount == 0
                                ? '0-0'
                                : '1-$transactionCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: Color(0xFFD1D5DB),
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
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isActive = _activeTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(bottom: BorderSide(color: Color(0xFF2563EB), width: 2))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive
                ? const Color(0xFF111827)
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTabContent(Vendor vendor, NumberFormat currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1 (Left details)
        Container(
          width: 360.0,
          height: 1262.26,
          decoration: const BoxDecoration(
            color: Color(0xFFFBFBFB),
            border: Border(
              right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contact Card (Light background, no border, customized design)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5FA),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.user,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Email & Portal links
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor.email ?? 'demo@gmail.com',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    InkWell(
                                      onTap: () {},
                                      child: const Text(
                                        'Invite to Portal',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF2563EB),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {},
                                      child: const Text(
                                        'Send Email',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF2563EB),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Gear icon
                          _OverviewSettingsMenu(
                            onEdit: () {
                              final vendorId = widget.vendorId;
                              if (vendorId == null) return;
                              final orgId = GoRouterState.of(context)
                                  .pathParameters['orgSystemId'];
                              final prefix = orgId != null ? '/$orgId' : '';
                              context.go('$prefix/purchases/vendors/$vendorId/edit');
                            },
                            onDelete: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Address Section (no Card border)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _addressExpanded = !_addressExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ADDRESS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Icon(
                            _addressExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 14,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                    if (_addressExpanded) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Billing Address',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 0,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _billingAddress == null
                                      ? 'No Billing Address - '
                                      : '${_formatAddressSummary(_billingAddress!)} - ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showAddressDialog(isBilling: true),
                                  child: Text(
                                    _billingAddress == null ? 'New Address' : 'Edit Address',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 0,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _shippingAddress == null
                                      ? 'No Shipping Address - '
                                      : '${_formatAddressSummary(_shippingAddress!)} - ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showAddressDialog(isBilling: false),
                                  child: Text(
                                    _shippingAddress == null ? 'New Address' : 'Edit Address',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),
                // Other Details Section (no Card border)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _otherDetailsExpanded = !_otherDetailsExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OTHER DETAILS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Icon(
                            _otherDetailsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 14,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                    if (_otherDetailsExpanded) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Vendor Number',
                              vendor.vendorNumber ?? '--',
                              showEditAction: true,
                            ),
                            _buildDetailRow(
                              'Default Currency',
                              vendor.currency ?? 'INR',
                              showEditAction: true,
                            ),
                            _buildDetailRow(
                              'GST Treatment',
                              vendor.gstTreatment ?? '--',
                              showEditAction: true,
                            ),
                            _buildDetailRow(
                              'Source of Supply',
                              'Kerala',
                              showEditAction: true,
                            ),
                            // Portal Status
                            MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _isPortalStatusHovered = true),
                              onExit: (_) =>
                                  setState(() => _isPortalStatusHovered = false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Portal Status',
                                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Disabled',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                          if (_isPortalStatusHovered) ...[
                                            const SizedBox(width: 8),
                                            ZTooltip(
                                              message:
                                                  'Configure the vendor portal access',
                                              child: InkWell(
                                                onTap: _showPortalAccessDialog,
                                                borderRadius: BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: Icon(
                                                    LucideIcons.settings,
                                                    size: 14,
                                                    color: Color(0xFF20263A),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _buildDetailRow(
                              'Vendor Language',
                              'English',
                              showEditAction: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),
                // Contact Persons Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _contactPersonsExpanded = !_contactPersonsExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONTACT PERSONS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _showAddContactPersonDialog,
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        LucideIcons.plus,
                                        size: 11.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _contactPersonsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 14,
                                color: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_contactPersonsExpanded) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'No contact persons found.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),
                // Bank Account Details Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _bankAccountDetailsExpanded = !_bankAccountDetailsExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BANK ACCOUNT DETAILS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _showAddBankAccountDialog(vendor),
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        LucideIcons.plus,
                                        size: 11.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _bankAccountDetailsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 14,
                                color: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_bankAccountDetailsExpanded) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'No bank account added yet',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),
                // Associate Tags Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _associateTagsExpanded = !_associateTagsExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ASSOCIATE TAGS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _showAssociateTagsDialog,
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(
                                        LucideIcons.plus,
                                        size: 11.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _associateTagsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                size: 14,
                                color: const Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_associateTagsExpanded) ...[
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Associate reporting tags to easily filter your contacts in reports',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 24),
                // Record Info Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _recordInfoExpanded = !_recordInfoExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECORD INFO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Icon(
                            _recordInfoExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 14,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                    if (_recordInfoExpanded) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Column(
                          children: [
                            _buildDetailRow('Vendor ID', vendor.id.isEmpty ? '216156300000034007' : vendor.id),
                            _buildDetailRow('Created On', '16-11-2024'),
                            _buildDetailRow('Created By', 'zabnixprivatelimited'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Column 2 (Right payables/timeline)
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Text(
                  'You can request your contact to directly update the GSTIN by sending an email. Send email',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                ),
              ),
              const SizedBox(height: 24),
              // Payment due period
              const Text(
                'Payment due period',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Net 360',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 24),
              // Payables Table
              const Text(
                'Payables',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Table(
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                    children: [
                      _buildTableHeaderCell('CURRENCY'),
                      _buildTableHeaderCell('OUTSTANDING PAYABLES'),
                      _buildTableHeaderCell('UNUSED CREDITS'),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildTableCell(vendor.currency ?? 'INR'),
                      _buildTableCell('--'),
                      _buildTableCell('--'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Items Ordered summary
              const Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    'Items to be received: 0.00',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total items ordered: 1.00',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Timeline activity
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 24),
              _buildTimeline(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTabContent() {
    final hasDraft = _commentController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 660,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9DEEA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCommentFormatButton(
                        label: 'B',
                        isActive: _isCommentBold,
                        onTap: () {
                          setState(() {
                            _isCommentBold = !_isCommentBold;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildCommentFormatButton(
                        label: 'I',
                        isActive: _isCommentItalic,
                        onTap: () {
                          setState(() {
                            _isCommentItalic = !_isCommentItalic;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildCommentFormatButton(
                        label: 'U',
                        isActive: _isCommentUnderlined,
                        onTap: () {
                          setState(() {
                            _isCommentUnderlined = !_isCommentUnderlined;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 92,
                  child: TextField(
                    controller: _commentController,
                    onChanged: (_) => setState(() {}),
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF20263A),
                      fontWeight: _isCommentBold
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontStyle: _isCommentItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      decoration: _isCommentUnderlined
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: hasDraft ? _addComment : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDraft
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        side: BorderSide(
                          color: hasDraft
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFFD8DCE8),
                        ),
                        minimumSize: const Size(104, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Add Comment',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 660,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    const Text(
                      'ALL COMMENTS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (_comments.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22A95E),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 22),
                if (_comments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No comments yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C86A2),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _comments
                        .map((comment) => _buildCommentCard(comment))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentFormatButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required TextStyle style,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: style.copyWith(
            color: const Color(0xFF20263A),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(_VendorCommentEntry comment) {
    final timestamp = DateFormat('dd-MM-yyyy hh:mm a').format(comment.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        width: 660,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE)),
              color: Colors.white,
            ),
            child: const Icon(
              LucideIcons.messageSquare,
              size: 15,
              color: Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C86A2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          comment.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF111827),
                            fontWeight: comment.isBold
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontStyle: comment.isItalic
                                ? FontStyle.italic
                                : FontStyle.normal,
                            decoration: comment.isUnderlined
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _deleteComment(comment),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: Color(0xFF7C86A2),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool showEditAction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 6,
            child: showEditAction
                ? _OverviewEditableDetailValue(value: value)
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineItem(
          title: 'Purchase Order updated',
          description: 'Items received for Purchase Order PO-00043 by zabnixprivatelimited - View Details',
          timestamp: '11-06-2026 02:12 PM',
          isFirst: true,
        ),
        _buildTimelineItem(
          title: 'Purchase Order updated',
          description: 'Purchase Order PO-00042 marked as sent',
          timestamp: '11-06-2026 12:27 PM',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String description,
    required String timestamp,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B82F6), width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewListOptionsMenu extends StatelessWidget {
  final String sortByField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSortChanged;
  final VoidCallback onRefresh;
  final VoidCallback onResetColumnWidths;
  final VoidCallback onCustomizeColumns;

  const _OverviewListOptionsMenu({
    required this.sortByField,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onResetColumnWidths,
    required this.onCustomizeColumns,
  });

  ButtonStyle _menuItemButtonStyle() {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return Colors.white;
        }
        return const Color(0xFF20263A);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFF3B82F6);
        }
        return Colors.white;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  MenuItemButton _buildSortSubmenuItem(String field) {
    final isActive = sortByField == field;
    return MenuItemButton(
      onPressed: () {
        if (isActive) {
          onSortChanged(field, !sortAscending);
        } else {
          onSortChanged(field, true);
        }
      },
      style: _menuItemButtonStyle(),
      trailingIcon: isActive
          ? Icon(
              sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 14,
              color: Colors.white,
            )
          : null,
      child: Text(field, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-160, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: Color(0xFF4B5563),
            ),
            padding: EdgeInsets.zero,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        );
      },
      menuChildren: [
        SubmenuButton(
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
          submenuIcon: const WidgetStatePropertyAll(
            Icon(LucideIcons.chevronRight, size: 14),
          ),
          menuChildren: [
            _buildSortSubmenuItem('Name'),
            _buildSortSubmenuItem('Vendor Number'),
            _buildSortSubmenuItem('Company Name'),
            _buildSortSubmenuItem('Email'),
            _buildSortSubmenuItem('Phone'),
            _buildSortSubmenuItem('GST Treatment'),
            _buildSortSubmenuItem('Payables'),
            _buildSortSubmenuItem('Payables (BCY)'),
            _buildSortSubmenuItem('Unused Credits'),
            _buildSortSubmenuItem('Unused Credits (BCY)'),
            _buildSortSubmenuItem('Status'),
          ],
          child: const Text('Sort by', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Import Vendors clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileInput, size: 16),
          child: const Text('Import Vendors', style: TextStyle(fontSize: 13)),
        ),
        SubmenuButton(
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.fileOutput, size: 16),
          submenuIcon: const WidgetStatePropertyAll(
            Icon(LucideIcons.chevronRight, size: 14),
          ),
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as PDF clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileDown, size: 16),
              child: const Text('Export as PDF', style: TextStyle(fontSize: 13)),
            ),
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as CSV clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              child: const Text('Export as CSV', style: TextStyle(fontSize: 13)),
            ),
            MenuItemButton(
              onPressed: () {
                ZerpaiToast.success(context, 'Export as Excel clicked');
              },
              style: _menuItemButtonStyle(),
              leadingIcon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              child: const Text(
                'Export as Excel',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
          child: const Text('Export', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Preferences clicked');
          },
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(
            LucideIcons.settings,
            size: 16,
            color: Color(0xFF20263A),
          ),
          child: const Text('Preferences', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: onCustomizeColumns,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.sliders, size: 16),
          child: const Text(
            'Manage Custom Fields',
            style: TextStyle(fontSize: 13),
          ),
        ),
        MenuItemButton(
          onPressed: onRefresh,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
          child: const Text('Refresh List', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: onResetColumnWidths,
          style: _menuItemButtonStyle(),
          leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
          child: const Text(
            'Reset Column Width',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _OverviewEditableDetailValue extends StatefulWidget {
  const _OverviewEditableDetailValue({required this.value});

  final String value;

  @override
  State<_OverviewEditableDetailValue> createState() =>
      _OverviewEditableDetailValueState();
}

class _OverviewEditableDetailValueState
    extends State<_OverviewEditableDetailValue> {
  bool _isHovered = false;
  bool _isEditing = false;
  bool _isCancelHovered = false;
  late final TextEditingController _controller;
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = TextEditingController(text: _currentValue);
  }

  @override
  void didUpdateWidget(covariant _OverviewEditableDetailValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _currentValue = widget.value;
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = _currentValue;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _saveEditing() {
    setState(() {
      _currentValue = _controller.text.trim().isEmpty
          ? _currentValue
          : _controller.text.trim();
      _controller.text = _currentValue;
      _isEditing = false;
      _isHovered = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _controller.text = _currentValue;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF6EA8FE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _saveEditing(),
              ),
            ),
            InkWell(
              onTap: _saveEditing,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22B573),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _isCancelHovered = true),
              onExit: (_) => setState(() => _isCancelHovered = false),
              child: InkWell(
                onTap: _cancelEditing,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _isCancelHovered
                        ? const Color(0xFFFFD6D6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF7F6FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentValue,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_isHovered) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: _startEditing,
                child: const Icon(
                  LucideIcons.pencil,
                  size: 13,
                  color: Color(0xFF73788C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewSettingsMenu extends StatelessWidget {
  const _OverviewSettingsMenu({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        shadowColor: WidgetStateProperty.all(const Color(0x14000000)),
        elevation: WidgetStateProperty.all(6),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(const Size(130, 88.25)),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFFEBEAF2)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      menuChildren: [
        _OverviewSettingsMenuItem(
          label: 'Edit',
          isFirst: true,
          onPressed: onEdit,
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFEBEAF2),
        ),
        _OverviewSettingsMenuItem(
          label: 'Delete',
          isLast: true,
          onPressed: onDelete,
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(
            LucideIcons.settings,
            size: 16,
            color: Color(0xFF20263A),
          ),
          splashRadius: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 18, height: 18),
        );
      },
    );
  }
}

class _OverviewSettingsMenuItem extends StatelessWidget {
  const _OverviewSettingsMenuItem({
    required this.label,
    required this.onPressed,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(6) : Radius.zero,
      bottom: isLast ? const Radius.circular(6) : Radius.zero,
    );

    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14),
        ),
        minimumSize: WidgetStateProperty.all(const Size(130, 44.125)),
        maximumSize: WidgetStateProperty.all(const Size(130, 44.125)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return const Color(0xFF3B82F6);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return Colors.white;
          }
          return const Color(0xFF4B5563);
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _VendorOverviewAddressDialog extends ConsumerStatefulWidget {
  const _VendorOverviewAddressDialog({
    required this.title,
    required this.onSave,
    this.initialAddress,
  });

  final String title;
  final Map<String, dynamic>? initialAddress;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  ConsumerState<_VendorOverviewAddressDialog> createState() =>
      _VendorOverviewAddressDialogState();
}

class _VendorOverviewAddressDialogState
    extends ConsumerState<_VendorOverviewAddressDialog> {
  final TextEditingController _attentionController = TextEditingController();
  final TextEditingController _street1Controller = TextEditingController();
  final TextEditingController _street2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _faxController = TextEditingController();

  Map<String, String>? _selectedCountry;
  Map<String, String>? _selectedState;
  String _phoneCode = '+91';

  static const List<String> _phoneCodes = [
    '+91',
    '+1',
    '+44',
    '+65',
    '+971',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress ?? <String, dynamic>{};
    _attentionController.text = (initial['attention'] ?? '').toString();
    _street1Controller.text = (initial['street1'] ?? '').toString();
    _street2Controller.text = (initial['street2'] ?? '').toString();
    _cityController.text = (initial['city'] ?? '').toString();
    _pinCodeController.text = (initial['zip'] ?? '').toString();
    _faxController.text = (initial['fax'] ?? '').toString();
    _phoneCode = (initial['phoneCode'] ?? '+91').toString();
    _phoneController.text = (initial['phone'] ?? '').toString();

    final countryId = (initial['country'] ?? '').toString();
    final countryName = (initial['countryName'] ?? '').toString();
    if (countryId.isNotEmpty || countryName.isNotEmpty) {
      _selectedCountry = {
        'id': countryId,
        'name': countryName,
      };
    }

    final stateId = (initial['state'] ?? '').toString();
    final stateName = (initial['stateName'] ?? '').toString();
    if (stateId.isNotEmpty || stateName.isNotEmpty) {
      _selectedState = {
        'id': stateId,
        'name': stateName,
      };
    }
  }

  @override
  void dispose() {
    _attentionController.dispose();
    _street1Controller.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _pinCodeController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF8A8FB2),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD6D9EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD6D9EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF20263A),
        ),
      ),
    );
  }

  Widget _dropdownRow(String label, bool isSelected, bool isHovered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6)
            : isSelected
                ? const Color(0xFFF3F4F6)
                : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isHovered ? Colors.white : const Color(0xFF374151),
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(countriesProvider(null));
    final countries = countriesAsync.value ?? const <Map<String, String>>[];
    if (_selectedCountry != null &&
        (_selectedCountry!['name']?.isEmpty ?? true) &&
        countries.isNotEmpty) {
      final foundCountry = countries.where((country) {
        return country['id'] == _selectedCountry!['id'];
      }).toList();
      if (foundCountry.isNotEmpty) {
        _selectedCountry = foundCountry.first;
      }
    }

    final countryId = _selectedCountry?['id'] ?? '';
    final statesAsync = ref.watch(statesProvider(countryId));
    final states = statesAsync.value ?? const <Map<String, String>>[];
    if (_selectedState != null &&
        (_selectedState!['name']?.isEmpty ?? true) &&
        states.isNotEmpty) {
      final foundState = states.where((state) {
        return state['id'] == _selectedState!['id'];
      }).toList();
      if (foundState.isNotEmpty) {
        _selectedState = foundState.first;
      }
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          height: 877.79,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDADCE8)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE3E6F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF20263A),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF73788C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Attention'),
                      TextField(
                        controller: _attentionController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _label('Country/Region'),
                      FormDropdown<Map<String, String>>(
                        height: 32,
                        hint: 'Select',
                        value: _selectedCountry,
                        items: countries,
                        isLoading: countriesAsync.isLoading,
                        border: Border.all(color: const Color(0xFFD6D9EB)),
                        displayStringForValue: (value) => value['name'] ?? '',
                        itemBuilder: (item, isSelected, isHovered) =>
                            _dropdownRow(
                          item['name'] ?? '',
                          isSelected,
                          isHovered,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedState = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('Address'),
                      TextField(
                        controller: _street1Controller,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Street 1'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _street2Controller,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hintText: 'Street 2'),
                      ),
                      const SizedBox(height: 14),
                      _label('City'),
                      TextField(
                        controller: _cityController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('State'),
                                FormDropdown<Map<String, String>>(
                                  height: 32,
                                  hint: 'Select or type to add',
                                  value: _selectedState,
                                  items: states,
                                  isLoading: statesAsync.isLoading,
                                  border: Border.all(
                                    color: const Color(0xFFD6D9EB),
                                  ),
                                            displayStringForValue: (value) =>
                                      value['name'] ?? '',
                                  itemBuilder:
                                      (item, isSelected, isHovered) =>
                                          _dropdownRow(
                                    item['name'] ?? '',
                                    isSelected,
                                    isHovered,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedState = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Pin Code'),
                                TextField(
                                  controller: _pinCodeController,
                                  style: const TextStyle(fontSize: 13),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: _inputDecoration(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Phone'),
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFD6D9EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 64,
                                        child: FormDropdown<String>(
                                          height: 30,
                                          hint: '+91',
                                          value: _phoneCode,
                                          items: _phoneCodes,
                                          border: Border.all(
                                            color: Colors.transparent,
                                          ),
                                          displayStringForValue: (value) =>
                                              value,
                                          itemBuilder:
                                              (item, isSelected, isHovered) =>
                                                  _dropdownRow(
                                            item,
                                            isSelected,
                                            isHovered,
                                          ),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _phoneCode = value;
                                            });
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 32,
                                        color: const Color(0xFFD6D9EB),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneController,
                                          style: const TextStyle(fontSize: 13),
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              10,
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 9,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Fax Number'),
                                TextField(
                                  controller: _faxController,
                                  style: const TextStyle(fontSize: 13),
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.info,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.55,
                                    color: Color(0xFF163B73),
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          'This address will apply only to future transactions.\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'To update for existing transactions, select them in the respective module and update the address using ',
                                    ),
                                    TextSpan(
                                      text: 'Bulk Update. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Learn More',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE3E6F0)),
                  ),
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        widget.onSave({
                          'attention': _attentionController.text.trim(),
                          'street1': _street1Controller.text.trim(),
                          'street2': _street2Controller.text.trim(),
                          'city': _cityController.text.trim(),
                          'zip': _pinCodeController.text.trim(),
                          'phoneCode': _phoneCode,
                          'phone': _phoneController.text.trim(),
                          'fax': _faxController.text.trim(),
                          'country': _selectedCountry?['id'] ?? '',
                          'countryName': _selectedCountry?['name'] ?? '',
                          'state': _selectedState?['id'] ?? '',
                          'stateName': _selectedState?['name'] ?? '',
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6AD3AA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(49, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF20263A),
                        side: const BorderSide(color: Color(0xFFD6D9EB)),
                        minimumSize: const Size(57, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13),
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
  }
}

class _VendorPortalAccessDialog extends StatefulWidget {
  const _VendorPortalAccessDialog();

  @override
  State<_VendorPortalAccessDialog> createState() =>
      _VendorPortalAccessDialogState();
}

class _VendorPortalAccessDialogState extends State<_VendorPortalAccessDialog> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 700,
        height: 212.03,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Configure Portal Access',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF20263A),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 20),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: Text(
                            'NAME',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Color(0xFF7C86A2),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            'EMAIL ADDRESS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Color(0xFF7C86A2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Checkbox(
                            value: _isChecked,
                            onChanged: (value) {
                              setState(() {
                                _isChecked = value ?? false;
                              });
                            },
                            side: const BorderSide(color: Color(0xFFC7CDDE)),
                            activeColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 5,
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF20263A),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 6,
                          child: Text(
                            'demo@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF20263A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22B573),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(57, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF20263A),
                            side: const BorderSide(color: Color(0xFFD8DCE8)),
                            minimumSize: const Size(66, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 13),
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
}

class _VendorBankAccountDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final String accountHolderName;

  const _VendorBankAccountDialog({
    required this.vendorId,
    required this.accountHolderName,
  });

  @override
  ConsumerState<_VendorBankAccountDialog> createState() =>
      _VendorBankAccountDialogState();
}

class _VendorBankAccountDialogState
    extends ConsumerState<_VendorBankAccountDialog> {
  bool _saving = false;
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _reEnterAccountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accountHolderController.text = widget.accountHolderName;
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _reEnterAccountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9AA3B8),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD7DCEC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD7DCEC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isRequired ? '$text*' : text,
        style: TextStyle(
          fontSize: 12,
          color: isRequired ? const Color(0xFFFF3B30) : const Color(0xFF2B3245),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final account = _accountNumberController.text.trim();
    final reenter = _reEnterAccountNumberController.text.trim();
    final ifsc = _ifscController.text.trim();

    if (account.isEmpty) {
      ZerpaiToast.error(context, 'Account number is required');
      return;
    }
    if (account != reenter) {
      ZerpaiToast.error(context, 'Account numbers do not match');
      return;
    }
    if (ifsc.isEmpty) {
      ZerpaiToast.error(context, 'IFSC is required');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(vendorRepositoryProvider)
          .addBankAccount(
            widget.vendorId,
            holderName: _accountHolderController.text,
            bankName: _bankNameController.text,
            accountNumber: account,
            ifsc: ifsc,
          );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Bank account added');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ZerpaiToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 600,
        height: 602.38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Add Bank Account Details',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF20263A),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Account Holder Name'),
                    TextField(
                      controller: _accountHolderController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2B3245),
                      ),
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8EBF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F2FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  LucideIcons.landmark,
                                  size: 30,
                                  color: Color(0xFF2F80ED),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Bank Name'),
                                    TextField(
                                      controller: _bankNameController,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2B3245),
                                      ),
                                      decoration: _fieldDecoration(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Account Number', isRequired: true),
                          TextField(
                            controller: _accountNumberController,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2B3245),
                            ),
                            decoration: _fieldDecoration(
                              suffixIcon: const Icon(
                                LucideIcons.eye,
                                size: 16,
                                color: Color(0xFF8C94AB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel(
                            'Re-enter Account Number',
                            isRequired: true,
                          ),
                          TextField(
                            controller: _reEnterAccountNumberController,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2B3245),
                            ),
                            decoration: _fieldDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('IFSC', isRequired: true),
                    TextField(
                      controller: _ifscController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2B3245),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(11),
                        UpperCaseTextFormatter(),
                      ],
                      decoration: _fieldDecoration(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22B573),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(58, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF20263A),
                      side: const BorderSide(color: Color(0xFFD8DCE8)),
                      minimumSize: const Size(70, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13),
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
}

class _VendorAssociateTagsDialog extends StatefulWidget {
  const _VendorAssociateTagsDialog();

  @override
  State<_VendorAssociateTagsDialog> createState() =>
      _VendorAssociateTagsDialogState();
}

class _VendorAssociateTagsDialogState
    extends State<_VendorAssociateTagsDialog> {
  static const List<String> _tagOptions = ['None', 'Option 1', 'Option 2'];

  String _adgfValue = 'None';
  String _scheduleValue = 'None';
  String _demoTagValue = 'None';

  Widget _dropdownRow(String label, bool isSelected, bool isHovered) {
    final highlighted = isSelected || isHovered;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF3B82F6) : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: highlighted ? Colors.white : const Color(0xFF20263A),
        ),
      ),
    );
  }

  Widget _buildTagRow({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 230,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2B3245),
              ),
            ),
          ),
          Expanded(
            child: FormDropdown<String>(
              height: 38,
              hint: 'None',
              value: value,
              items: _tagOptions,
              border: Border.all(color: const Color(0xFFD7DCEC)),
              displayStringForValue: (item) => item,
              itemBuilder: (item, isSelected, isHovered) =>
                  _dropdownRow(item, isSelected, isHovered),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 500,
        height: 318.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Associate Tags',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF20263A),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFF20263A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  children: [
                    _buildTagRow(
                      label: 'ADGF',
                      value: _adgfValue,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _adgfValue = value;
                        });
                      },
                    ),
                    _buildTagRow(
                      label: 'schedule',
                      value: _scheduleValue,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _scheduleValue = value;
                        });
                      },
                    ),
                    _buildTagRow(
                      label: 'demo advaced reporting tag',
                      value: _demoTagValue,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _demoTagValue = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22B573),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(58, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF20263A),
                      side: const BorderSide(color: Color(0xFFD8DCE8)),
                      minimumSize: const Size(74, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13),
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
}

class _VendorCommentEntry {
  final String author;
  final DateTime timestamp;
  final String message;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;

  const _VendorCommentEntry({
    required this.author,
    required this.timestamp,
    required this.message,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
  });
}

class _AttachmentUploadCard extends StatelessWidget {
  const _AttachmentUploadCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: CustomPaint(
        painter: const _AttachmentDashedBorderPainter(),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                LucideIcons.upload,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Upload your Files',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(width: 6),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentFileRow extends StatelessWidget {
  const _AttachmentFileRow({
    required this.file,
    required this.onRemove,
    required this.formatFileSize,
  });

  final PlatformFile file;
  final VoidCallback onRemove;
  final String Function(int bytes) formatFileSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.file,
              size: 15,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatFileSize(file.size),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentDashedBorderPainter extends CustomPainter {
  const _AttachmentDashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    final borderPath = Path()..addRRect(rect);
    final paint = Paint()
      ..color = const Color(0xFFD7DDE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashGap = 3.0;

    for (final metric in borderPath.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VendorTransactionRow {
  final String date;
  final String location;
  final String billNo;
  final String orderNumber;
  final String vendorName;
  final String amount;
  final String balanceDue;
  final String status;
  final Color statusColor;

  const _VendorTransactionRow({
    required this.date,
    required this.location,
    required this.billNo,
    required this.orderNumber,
    required this.vendorName,
    required this.amount,
    required this.balanceDue,
    required this.status,
    required this.statusColor,
  });
}
