import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/providers/purchases_payments_made_provider.dart' as pm_prov;
import 'package:zerpai_erp/modules/purchases/payments_made/models/purchases_payments_made_model.dart' as pm_model;
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/shared/widgets/email_composer.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/widgets/payment_corner_ribbon.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/web_safe_platform_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class PaymentMade {
  final String? dbId;
  final String id; // maps to paymentNumber
  final String entityId;
  final String vendorId;
  final String paymentType;
  final String date;
  final String location;
  final String referenceNumber;
  final String vendorName;
  final String billNumber;
  final String mode;
  final String status;
  final double amount;
  final double unusedAmount;
  final double totalRefunded;
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
    this.entityId = '',
    this.vendorId = '',
    this.paymentType = 'RECORD_PAYMENT',
    required this.date,
    required this.location,
    required this.referenceNumber,
    required this.vendorName,
    required this.billNumber,
    required this.mode,
    required this.status,
    required this.amount,
    required this.unusedAmount,
    this.totalRefunded = 0.0,
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

class PaymentNumberPreferences {
  const PaymentNumberPreferences({
    required this.autoGenerate,
    required this.autoPrefix,
    required this.nextNumber,
    required this.manualPrefix,
    required this.manualPaymentNumber,
    required this.restartFiscalYear,
  });

  final bool autoGenerate;
  final String autoPrefix;
  final String nextNumber;
  final String manualPrefix;
  final String manualPaymentNumber;
  final bool restartFiscalYear;
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

  // Filter dropdown (MenuAnchor)
  final MenuController _filterMenuController = MenuController();
  // PDF/Print dropdown (MenuAnchor)
  final MenuController _pdfPrintMenuController = MenuController();
  // Right action bar more dropdown (MenuAnchor)
  final MenuController _rightMoreMenuController = MenuController();
  // Customize dropdown (MenuAnchor)
  final MenuController _customizeMenuController = MenuController();
  // Bulk actions dropdown (MenuAnchor)
  final MenuController _bulkMenuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _viewIsStarred = false;


  final LayerLink _attachmentLink = LayerLink();
  OverlayEntry? _attachmentOverlayEntry;
  bool _isAttachmentPopoverOpen = false;
  bool _showCommentsPanel = false;

  // Row checkbox selection
  final Set<String> _checkedIds = {};
  String? _hoveredId;

  // Template chooser panel
  String _selectedTemplate = 'Standard Template';
  bool _isDocumentHovered = false;
  List<PlatformFile> _uploadedFiles = [];
  String _sortByField = 'date';
  bool _isRefundView = false;
  final TextEditingController _refundAmountController = TextEditingController();
  final TextEditingController _refundDateController = TextEditingController();
  final TextEditingController _refundReferenceController =
      TextEditingController();
  final TextEditingController _refundSupplyDescriptionController =
      TextEditingController();
  final TextEditingController _refundDescriptionController =
      TextEditingController();
  final GlobalKey _refundDateFieldKey = GlobalKey();
  DateTime _refundDateValue = DateTime.now();
  String? _refundPaymentMode;
  String? _refundToAccount;
  Future<List<_PaymentsMadeRefundRow>>? _refundDetailsFuture;
  String? _refundDetailsPaymentDbId;
  bool _isRefundHistoryExpanded = true;
  _PaymentsMadeRefundRow? _editingRefundRow;

  static const List<String> _defaultRefundPaymentModeOptions = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'UPI',
  ];
  List<String> _refundPaymentModeOptions = List<String>.from(
    _defaultRefundPaymentModeOptions,
  );
  String? _refundPaymentModesEntityId;

  @override
  void initState() {
    super.initState();
    _payments = List.from(_mockPayments);
    _selectedPayment = _payments.first;
    _seedRefundForm();
    _loadPaymentsFromDb();
    _loadRefundPaymentModes();
    _refreshRefundDetailsFuture();
    _loadAttachmentsForSelectedPayment();
  }

  Future<void> _loadPaymentsFromDb() async {
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('payment_made_master')
          .select('*, vendors(*), payment_made_tax(*)')
          .order('payment_date', ascending: false);

      final paidThroughIds = (rows as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .map((row) => (row['paid_through_account_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final Map<String, String> accountNamesById = <String, String>{};
      if (paidThroughIds.isNotEmpty) {
        final accountRows = await supabase
            .from('accounts')
            .select('id, user_account_name, system_account_name')
            .inFilter('id', paidThroughIds);
        for (final raw in accountRows as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          final accountId = (row['id'] ?? '').toString();
          if (accountId.isEmpty) continue;
          accountNamesById[accountId] =
              _firstNonEmpty([
                row['user_account_name'],
                row['system_account_name'],
              ]) ??
              accountId;
        }
      }

      final orgSettings = ref.read(orgSettingsProvider).whenOrNull(data: (s) => s);
      final String resolvedCompanyName = orgSettings?.name ?? 'ZABNIX PRIVATE LIMITED';
      final String resolvedCompanyEmail = orgSettings?.email ?? 'zabnixprivatelimited@gmail.com';
      final String resolvedCompanyPhone = orgSettings?.phone ?? '8086355500';
      final String resolvedCompanyGstin = orgSettings?.companyIdValue ?? '32AACCZ4912F1ZL';
      final List<String> resolvedCompanyAddress = [];
      if (orgSettings != null) {
        if (orgSettings.street != null && orgSettings.street!.trim().isNotEmpty) {
          resolvedCompanyAddress.add(orgSettings.street!.trim());
        }
        if (orgSettings.place != null && orgSettings.place!.trim().isNotEmpty) {
          resolvedCompanyAddress.add(orgSettings.place!.trim());
        }
        if (orgSettings.city != null && orgSettings.city!.trim().isNotEmpty) {
          resolvedCompanyAddress.add(orgSettings.city!.trim());
        }
        final country = orgSettings.country ?? 'India';
        final pincode = orgSettings.pincode ?? '';
        final line = '$country $pincode'.trim();
        if (line.isNotEmpty) {
          resolvedCompanyAddress.add(line);
        }
      }
      if (resolvedCompanyAddress.isEmpty) {
        resolvedCompanyAddress.addAll([
          'PERINTHALMANNA',
          'MALAPPURAM Kerala 679322',
          'India',
        ]);
      }

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
        final paymentAmount =
            double.tryParse((row['payment_amount'] ?? '0').toString()) ?? 0.0;
        final paidThroughId = (row['paid_through_account_id'] ?? '').toString();

        return PaymentMade(
          dbId: row['id']?.toString(),
          id: _firstNonEmpty([
                row['payment_number'],
                row['id'],
              ]) ??
              '',
          entityId: (row['entity_id'] ?? '').toString(),
          vendorId: (row['vendor_id'] ?? '').toString(),
          paymentType: (row['payment_type'] ?? 'RECORD_PAYMENT').toString(),
          date: paymentDate != null
              ? DateFormat('dd-MM-yyyy').format(paymentDate)
              : '',
          location: resolvedCompanyName,
          companyName: resolvedCompanyName,
          companyEmail: resolvedCompanyEmail,
          companyPhone: resolvedCompanyPhone,
          companyGstin: resolvedCompanyGstin,
          companyAddress: resolvedCompanyAddress,
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
          amount: paymentAmount,
          unusedAmount:
              double.tryParse((row['excess_amount'] ?? '0').toString()) ?? 0.0,
          totalRefunded:
              double.tryParse((row['total_refunded'] ?? '0').toString()) ?? 0.0,
          notes: (row['notes'] ?? '').toString(),
          paidThrough: accountNamesById[paidThroughId] ?? paidThroughId,
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
          amountInWords: _numberToWordsIndian(paymentAmount),
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
        _seedRefundForm();
      });
      _loadRefundPaymentModes();
      _refreshRefundDetailsFuture(force: true);
      _loadAttachmentsForSelectedPayment();
    } catch (e) {
      debugPrint('Error loading payments made: $e');
    }
  }

  String _numberToWordsIndian(double amount) {
    final roundedRupees = amount.floor();
    final paise = ((amount - roundedRupees) * 100).round();

    final rupeesPart = _convertNumberIndian(roundedRupees);
    if (paise <= 0) {
      return 'Indian Rupee $rupeesPart Only';
    }

    final paisePart = _convertNumberIndian(paise);
    return 'Indian Rupee $rupeesPart and Paise $paisePart Only';
  }

  String _convertNumberIndian(int number) {
    if (number == 0) return 'Zero';
    if (number < 0) return 'Minus ${_convertNumberIndian(-number)}';

    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convert(int value) {
      if (value < 20) return ones[value];
      if (value < 100) {
        return tens[value ~/ 10] +
            (value % 10 != 0 ? ' ${ones[value % 10]}' : '');
      }
      if (value < 1000) {
        return ones[value ~/ 100] +
            ' Hundred' +
            (value % 100 != 0 ? ' and ${convert(value % 100)}' : '');
      }
      if (value < 100000) {
        return convert(value ~/ 1000) +
            ' Thousand' +
            (value % 1000 != 0 ? ' ${convert(value % 1000)}' : '');
      }
      if (value < 10000000) {
        return convert(value ~/ 100000) +
            ' Lakh' +
            (value % 100000 != 0 ? ' ${convert(value % 100000)}' : '');
      }
      return convert(value ~/ 10000000) +
          ' Crore' +
          (value % 10000000 != 0 ? ' ${convert(value % 10000000)}' : '');
    }

    return convert(number).trim();
  }

  List<_RefundAccountOption> _buildRefundAccountOptions(List<AccountNode> roots) {
    final List<_RefundAccountOption> options = [];

    final List<AccountNode> allAccounts = [];
    void flatten(List<AccountNode> nodes) {
      for (final node in nodes) {
        allAccounts.add(node);
        if (node.children.isNotEmpty) {
          flatten(node.children);
        }
      }
    }

    flatten(roots);

    final Map<String, AccountNode> accountMap = {
      for (final acc in allAccounts) acc.id: acc,
    };

    final Set<String> parentIds = {};
    for (final acc in allAccounts) {
      if (acc.parentId != null && acc.parentId!.isNotEmpty) {
        parentIds.add(acc.parentId!);
      }
    }

    final Set<String> processedIds = {};

    for (final parentId in parentIds) {
      final parentNode = accountMap[parentId];
      if (parentNode == null) continue;

      options.add(
        _RefundAccountOption(parentNode.systemAccountName, isHeader: true),
      );
      processedIds.add(parentId);

      final children = allAccounts.where((acc) => acc.parentId == parentId).toList();
      for (final child in children) {
        options.add(
          _RefundAccountOption(
            child.systemAccountName,
            id: child.id,
            isBullet: true,
          ),
        );
        processedIds.add(child.id);
      }
    }

    for (final acc in allAccounts) {
      if (processedIds.contains(acc.id)) continue;

      final String nameLower = acc.systemAccountName.toLowerCase();
      if (nameLower == 'assets' ||
          nameLower == 'liabilities' ||
          nameLower == 'income' ||
          nameLower == 'expenses' ||
          nameLower == 'equity') {
        continue;
      }

      options.add(
        _RefundAccountOption(
          acc.systemAccountName,
          id: acc.id,
          isHeader: false,
          isBullet: false,
        ),
      );
    }

    return options;
  }

  _RefundAccountOption? _findRefundAccountOptionByLabel(
    List<_RefundAccountOption> options,
    String? label,
  ) {
    if (label == null || label.isEmpty) return null;
    for (final option in options) {
      if (!option.isHeader && option.label == label) {
        return option;
      }
    }
    return null;
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

  Future<void> _loadRefundPaymentModes() async {
    final entityId = _selectedPayment.entityId.trim();
    if (entityId.isEmpty || _refundPaymentModesEntityId == entityId) {
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      var response = await supabase
          .from('payment_made_payment_mode')
          .select('name, is_default')
          .eq('entity_id', entityId)
          .eq('is_deleted', false)
          .order('name');

      if (response.isEmpty) {
        final seedRows = _defaultRefundPaymentModeOptions
            .map(
              (mode) => <String, dynamic>{
                'entity_id': entityId,
                'name': mode,
                'is_default': mode.toLowerCase() == 'cash',
                'is_deleted': false,
              },
            )
            .toList(growable: false);

        await supabase.from('payment_made_payment_mode').insert(seedRows);

        response = await supabase
            .from('payment_made_payment_mode')
            .select('name, is_default')
            .eq('entity_id', entityId)
            .eq('is_deleted', false)
            .order('name');
      }

      if (!mounted) return;

      final loadedModes = List<String>.from(
        (response as List).map((e) => (e['name'] ?? '').toString()),
      ).where((mode) => mode.trim().isNotEmpty).toList(growable: false);

      if (loadedModes.isEmpty) return;

      final hasDefault = response.any((e) => e['is_default'] == true);
      final defaultMode = hasDefault
          ? (response.firstWhere((e) => e['is_default'] == true)['name'] ?? '')
                .toString()
          : loadedModes.first;

      setState(() {
        _refundPaymentModesEntityId = entityId;
        _refundPaymentModeOptions = loadedModes;

        final preferredMode = _editingRefundRow?.refundMode.isNotEmpty == true
            ? _editingRefundRow!.refundMode
            : _selectedPayment.mode;

        if (preferredMode.isNotEmpty &&
            _refundPaymentModeOptions.contains(preferredMode)) {
          _refundPaymentMode = preferredMode;
        } else if (_refundPaymentMode != null &&
            _refundPaymentModeOptions.contains(_refundPaymentMode)) {
          _refundPaymentMode = _refundPaymentMode;
        } else {
          _refundPaymentMode = defaultMode;
        }
      });
    } catch (e) {
      debugPrint('Failed to load refund payment modes: $e');
    }
  }

  Future<List<_PaymentsMadeRefundRow>> _loadRefundDetailsForPayment(
    PaymentMade payment,
  ) async {
    final dbPaymentId = payment.dbId?.trim() ?? '';
    if (dbPaymentId.isEmpty) return const <_PaymentsMadeRefundRow>[];

    final rows = await Supabase.instance.client
        .from('audit_logs')
        .select('id, action, created_at, new_values, old_values')
        .eq('table_name', 'payment_made_master')
        .eq('record_id', dbPaymentId)
        .inFilter('action', ['REFUND', 'REFND_EDIT', 'REFND_DEL'])
        .order('created_at', ascending: true);

    final orderedRows = <_PaymentsMadeRefundRow>[];
    final rowIndexesByNumber = <String, int>{};

    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final action = (row['action'] ?? '').toString().trim();
      final values = row['new_values'] is Map
          ? Map<String, dynamic>.from(row['new_values'] as Map)
          : row['old_values'] is Map
          ? Map<String, dynamic>.from(row['old_values'] as Map)
          : <String, dynamic>{};

      final refundRow = _PaymentsMadeRefundRow(
        id: (row['id'] ?? '').toString(),
        createdAt: (row['created_at'] ?? '').toString(),
        refundDate: (values['refund_date'] ?? '').toString(),
        refundNumber: (values['refund_number'] ?? '').toString(),
        refundMode: (values['refund_mode'] ?? '').toString(),
        accountName: (values['account_name'] ?? '').toString(),
        referenceNumber: (values['reference_number'] ?? '').toString(),
        description: (values['description'] ?? '').toString(),
        supplyDescription: (values['supply_description'] ?? '').toString(),
        refundAmount:
            double.tryParse((values['refund_amount'] ?? '0').toString()) ?? 0.0,
      );

      if (refundRow.refundNumber.isEmpty) {
        continue;
      }

      if (action == 'REFND_DEL') {
        final existingIndex = rowIndexesByNumber.remove(refundRow.refundNumber);
        if (existingIndex != null) {
          orderedRows.removeAt(existingIndex);
          rowIndexesByNumber
            ..clear()
            ..addEntries(
              orderedRows.asMap().entries.map(
                (entry) => MapEntry(entry.value.refundNumber, entry.key),
              ),
            );
        }
        continue;
      }

      final existingIndex = rowIndexesByNumber[refundRow.refundNumber];
      if (existingIndex == null) {
        rowIndexesByNumber[refundRow.refundNumber] = orderedRows.length;
        orderedRows.add(refundRow);
      } else {
        orderedRows[existingIndex] = refundRow;
      }
    }

    return orderedRows
        .where((row) => row.refundAmount > 0)
        .toList(growable: false);
  }

  void _refreshRefundDetailsFuture({bool force = false}) {
    final nextDbId = _selectedPayment.dbId?.trim() ?? '';
    if (!force &&
        _refundDetailsFuture != null &&
        _refundDetailsPaymentDbId == nextDbId) {
      return;
    }
    _refundDetailsPaymentDbId = nextDbId;
    _refundDetailsFuture = _loadRefundDetailsForPayment(_selectedPayment);
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
          _seedRefundForm();
        });
        _loadRefundPaymentModes();
        _refreshRefundDetailsFuture(force: true);
        _loadAttachmentsForSelectedPayment();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refundAmountController.dispose();
    _refundDateController.dispose();
    _refundReferenceController.dispose();
    _refundSupplyDescriptionController.dispose();
    _refundDescriptionController.dispose();
    super.dispose();
  }

  void _selectPayment(PaymentMade p) {
    setState(() {
      _selectedPayment = p;
      _seedRefundForm();
    });
    _loadRefundPaymentModes();
    _refreshRefundDetailsFuture(force: true);
    _loadAttachmentsForSelectedPayment();
    final state = GoRouterState.of(context);
    context.goNamed(
      state.name ?? AppRoutes.paymentsMade,
      pathParameters: state.pathParameters,
      queryParameters: {...state.uri.queryParameters, 'paymentId': p.id},
    );
  }

  void _seedRefundForm() {
    final balance = _selectedPayment.unusedAmount > 0
        ? _selectedPayment.unusedAmount
        : _selectedPayment.amount;
    _refundDateValue = DateTime.now();
    _refundAmountController.text = _formatRefundNumber(balance);
    _refundDateController.text = DateFormat(
      'dd-MM-yyyy',
    ).format(_refundDateValue);
    _refundReferenceController.clear();
    _refundSupplyDescriptionController.clear();
    _refundDescriptionController.clear();
    _refundPaymentMode = _refundPaymentModeOptions.contains(_selectedPayment.mode)
        ? _selectedPayment.mode
        : _refundPaymentModeOptions.first;
    _refundToAccount = _selectedPayment.paidThrough.trim().isEmpty
        ? null
        : _selectedPayment.paidThrough;
  }

  String _formatRefundNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double _refundBalanceAmount() {
    return _selectedPayment.unusedAmount > 0
        ? _selectedPayment.unusedAmount
        : _selectedPayment.amount;
  }

  void _openRefundView() {
    setState(() {
      _editingRefundRow = null;
      _seedRefundForm();
      _isRefundView = true;
    });
    _loadRefundPaymentModes();
  }

  Future<void> _openApplyToBillsDialog() async {
    if (_selectedPayment.paymentType.toUpperCase() != 'VENDOR_ADVANCE') {
      return;
    }
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => ApplyPaymentMadeToBillsDialog(
        payment: _selectedPayment,
      ),
    );
    if (applied == true) {
      await _loadPaymentsFromDb();
      if (mounted) {
        ZerpaiToast.success(
          context,
          'Bills updated from excess payment',
        );
      }
    }
  }

  void _openRefundEditView(_PaymentsMadeRefundRow row) {
    final parsedDate = row.refundDate.trim().isEmpty
        ? DateTime.now()
        : _parseDateString(row.refundDate);

    setState(() {
      _editingRefundRow = row;
      _refundDateValue = parsedDate;
      _refundDateController.text = row.refundDate;
      _refundAmountController.text = _formatRefundNumber(row.refundAmount);
      _refundReferenceController.text = row.referenceNumber;
      _refundSupplyDescriptionController.text = row.supplyDescription;
      _refundDescriptionController.text = row.description;
      if (row.refundMode.isNotEmpty &&
          !_refundPaymentModeOptions.contains(row.refundMode)) {
        _refundPaymentModeOptions = [
          ..._refundPaymentModeOptions,
          row.refundMode,
        ];
      }
      _refundPaymentMode = row.refundMode.isEmpty
          ? _refundPaymentModeOptions.first
          : row.refundMode;
      _refundToAccount = row.accountName.isEmpty ? _refundToAccount : row.accountName;
      _isRefundView = true;
    });
  }

  void _closeRefundView() {
    setState(() {
      _editingRefundRow = null;
      _isRefundView = false;
    });
  }

  Future<void> _saveRefund() async {
    try {
      final supabase = Supabase.instance.client;
      String? dbPaymentId = _selectedPayment.dbId;

      if (dbPaymentId == null || dbPaymentId.isEmpty) {
        final masterRows = await supabase
            .from('payment_made_master')
            .select('id')
            .eq('payment_number', _selectedPayment.id)
            .limit(1);
        if (masterRows.isNotEmpty) {
          dbPaymentId = masterRows.first['id']?.toString();
        }
      }

      if (dbPaymentId == null || dbPaymentId.isEmpty) {
        if (!mounted) return;
        ZerpaiToast.error(context, 'Payment not found for refund save.');
        return;
      }

      final refundAmount =
          double.tryParse(_refundAmountController.text.trim()) ?? 0.0;
      if (refundAmount <= 0) {
        if (!mounted) return;
        ZerpaiToast.error(context, 'Enter a valid refund amount.');
        return;
      }

      final existingRefunds = await supabase
          .from('audit_logs')
          .select('id')
          .eq('table_name', 'payment_made_master')
          .eq('record_id', dbPaymentId)
          .eq('action', 'REFUND');

      final paymentRows = await supabase
          .from('payment_made_master')
          .select('total_refunded, excess_amount, entity_id')
          .eq('id', dbPaymentId)
          .limit(1);
      final paymentRow = paymentRows.isNotEmpty
          ? Map<String, dynamic>.from(paymentRows.first as Map)
          : <String, dynamic>{};

      final previousRefundAmount = _editingRefundRow?.refundAmount ?? 0.0;
      final currentTotalRefunded =
          double.tryParse((paymentRow['total_refunded'] ?? '0').toString()) ??
          0.0;
      final currentExcessAmount =
          double.tryParse((paymentRow['excess_amount'] ?? '0').toString()) ??
          0.0;

      final refundNumber = _editingRefundRow?.refundNumber ??
          (((existingRefunds as List).length + 1).toString());
      final refundDateText = _refundDateController.text.trim();
      final refundMode = _refundPaymentMode ?? '';
      final accountName = _refundToAccount ?? '';
      final user = supabase.auth.currentUser;
      final payload = {
        'refund_date': refundDateText,
        'refund_number': refundNumber,
        'refund_mode': refundMode,
        'account_name': accountName,
        'refund_amount': refundAmount,
        'reference_number': _refundReferenceController.text.trim(),
        'description': _refundDescriptionController.text.trim(),
        'supply_description': _refundSupplyDescriptionController.text.trim(),
      };

      await supabase.from('audit_logs').insert({
        'table_name': 'payment_made_master',
        'record_id': dbPaymentId,
        'action': _editingRefundRow == null ? 'REFUND' : 'REFND_EDIT',
        'old_values': _editingRefundRow == null
            ? null
            : {
                'refund_date': _editingRefundRow!.refundDate,
                'refund_number': _editingRefundRow!.refundNumber,
                'refund_mode': _editingRefundRow!.refundMode,
                'account_name': _editingRefundRow!.accountName,
                'refund_amount': _editingRefundRow!.refundAmount,
                'reference_number': _editingRefundRow!.referenceNumber,
                'description': _editingRefundRow!.description,
                'supply_description': _editingRefundRow!.supplyDescription,
              },
        'new_values': payload,
        'user_id':
            user?.id ?? '00000000-0000-0000-0000-000000000000',
        'org_id': '00000000-0000-0000-0000-000000000000',
        'entity_id':
            (paymentRow['entity_id'] ?? _selectedPayment.entityId).toString(),
        'actor_name': user?.email?.split('@').first ?? 'system',
        'schema_name': 'public',
        'record_pk': _selectedPayment.id,
        'changed_columns': const ['total_refunded'],
        'source': 'ui',
        'module_name': 'payments_made',
      });

      await supabase
          .from('payment_made_master')
          .update({
            'total_refunded':
                currentTotalRefunded - previousRefundAmount + refundAmount,
            'excess_amount':
                (currentExcessAmount + previousRefundAmount - refundAmount) < 0
                ? 0
                : currentExcessAmount + previousRefundAmount - refundAmount,
          })
          .eq('id', dbPaymentId);

      await _loadPaymentsFromDb();
      _refreshRefundDetailsFuture(force: true);

      if (!mounted) return;
      ZerpaiToast.success(
        context,
        _editingRefundRow == null ? 'Refund saved' : 'Refund updated',
      );
      _closeRefundView();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save refund: $e');
    }
  }

  Future<Uint8List> _generateRefundPdf(
    _PaymentsMadeRefundRow row,
    NumberFormat currencyFormat,
  ) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'REFUND VOUCHER',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Payment #: ${_selectedPayment.id}',
                style: pw.TextStyle(font: regularFont, fontSize: 11),
              ),
              pw.Text(
                'Vendor: ${_selectedPayment.vendorName}',
                style: pw.TextStyle(font: regularFont, fontSize: 11),
              ),
              pw.SizedBox(height: 18),
              pw.Table(
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFE5E7EB),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.4),
                  1: pw.FlexColumnWidth(2.6),
                },
                children: [
                  _buildRefundPdfTableRow(
                    'Refund Date',
                    row.refundDate,
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Refund Number',
                    row.refundNumber,
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Payment Mode',
                    row.refundMode,
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Account Name',
                    row.accountName,
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Refund Amount',
                    currencyFormat.format(row.refundAmount),
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Reference#',
                    row.referenceNumber.isEmpty ? '-' : row.referenceNumber,
                    regularFont,
                    boldFont,
                  ),
                  _buildRefundPdfTableRow(
                    'Description',
                    row.description.isEmpty ? '-' : row.description,
                    regularFont,
                    boldFont,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.TableRow _buildRefundPdfTableRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          color: const PdfColor.fromInt(0xFFF9FAFB),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _printRefundRow(
    _PaymentsMadeRefundRow row,
    NumberFormat currencyFormat,
  ) async {
    final bytes = await _generateRefundPdf(row, currencyFormat);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  Future<void> _shareRefundRowPdf(
    _PaymentsMadeRefundRow row,
    NumberFormat currencyFormat,
  ) async {
    final bytes = await _generateRefundPdf(row, currencyFormat);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'refund-${_selectedPayment.id}-${row.refundNumber}.pdf',
    );
  }

  Future<void> _deleteRefundRow(_PaymentsMadeRefundRow row) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Refund',
      message:
          'Are you sure about deleting the refund made from this excess payment?',
      confirmLabel: 'OK',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.warning,
    );

    if (!confirmed) return;

    try {
      final supabase = Supabase.instance.client;
      final dbPaymentId = _selectedPayment.dbId?.trim() ?? '';
      if (dbPaymentId.isEmpty) return;

      final paymentRows = await supabase
          .from('payment_made_master')
          .select('total_refunded, excess_amount, entity_id')
          .eq('id', dbPaymentId)
          .limit(1);
      final paymentRow = paymentRows.isNotEmpty
          ? Map<String, dynamic>.from(paymentRows.first as Map)
          : <String, dynamic>{};

      final currentTotalRefunded =
          double.tryParse((paymentRow['total_refunded'] ?? '0').toString()) ??
          0.0;
      final currentExcessAmount =
          double.tryParse((paymentRow['excess_amount'] ?? '0').toString()) ??
          0.0;
      final user = supabase.auth.currentUser;

      await supabase.from('audit_logs').insert({
        'table_name': 'payment_made_master',
        'record_id': dbPaymentId,
        'action': 'REFND_DEL',
        'old_values': {
          'refund_date': row.refundDate,
          'refund_number': row.refundNumber,
          'refund_mode': row.refundMode,
          'account_name': row.accountName,
          'refund_amount': row.refundAmount,
          'reference_number': row.referenceNumber,
          'description': row.description,
          'supply_description': row.supplyDescription,
        },
        'new_values': {
          'refund_number': row.refundNumber,
        },
        'user_id':
            user?.id ?? '00000000-0000-0000-0000-000000000000',
        'org_id': '00000000-0000-0000-0000-000000000000',
        'entity_id':
            (paymentRow['entity_id'] ?? _selectedPayment.entityId).toString(),
        'actor_name': user?.email?.split('@').first ?? 'system',
        'schema_name': 'public',
        'record_pk': _selectedPayment.id,
        'changed_columns': const ['total_refunded'],
        'source': 'ui',
        'module_name': 'payments_made',
      });

      await supabase
          .from('payment_made_master')
          .update({
            'total_refunded': currentTotalRefunded - row.refundAmount < 0
                ? 0
                : currentTotalRefunded - row.refundAmount,
            'excess_amount': currentExcessAmount + row.refundAmount,
          })
          .eq('id', dbPaymentId);

      await _loadPaymentsFromDb();
      _refreshRefundDetailsFuture(force: true);
      if (!mounted) return;
      ZerpaiToast.success(context, 'Refund deleted');
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to delete refund: $e');
    }
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

  // ─── Filter Dropdown ──────────────────────────────────────────────────────────

  Widget _buildFilterDropdownContent() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ViewOptionRow(
            label: 'All Payments',
            isSelected: _selectedFilter == 'All',
            isStarred: _viewIsStarred,
            onTap: () {
              setState(() {
                _selectedFilter = 'All';
              });
              _filterMenuController.close();
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
              _filterMenuController.close();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New Custom View clicked')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── More Menu (left header three-dot) ──────────────────────────────────────

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

    // Apply Filter & Search Query
    final filteredPayments = _payments.where((p) {
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

    filteredPayments.sort((a, b) {
      int comparison = 0;
      switch (_sortByField) {
        case 'date':
          final dateA = _parseDateString(a.date);
          final dateB = _parseDateString(b.date);
          comparison = dateA.compareTo(dateB);
          break;
        case 'payment_no':
          final numA = int.tryParse(a.id) ?? 0;
          final numB = int.tryParse(b.id) ?? 0;
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
          final numA = int.tryParse(a.id) ?? 0;
          final numB = int.tryParse(b.id) ?? 0;
          comparison = numA.compareTo(numB);
          break;
        default:
          final dateA = _parseDateString(a.date);
          final dateB = _parseDateString(b.date);
          comparison = dateA.compareTo(dateB);
      }
      return comparison;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SplitListDetailLayout(
            leftWidth: 320,
            leftHeader: _buildLeftHeader(filteredPayments),
            leftBody: _buildLeftList(filteredPayments, currencyFormat),
            rightHeader: _buildRightHeader(),
            rightBody: _buildRightBody(currencyFormat),
          ),
          if (_showCommentsPanel) _buildCommentsHistoryPanel(currencyFormat),
        ],
      ),
    );
  }

  // ─── Left Panel Header ──────────────────────────────────────────────────────

  Widget _buildLeftHeader(List<PaymentMade> filteredList) {
    // Bulk actions bar
    if (_checkedIds.isNotEmpty) {
      return Container(
        height: 60,
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
                              entityId: p.entityId,
                              vendorId: p.vendorId,
                              paymentType: p.paymentType,
                              date: updatedDate,
                              location: updatedLocation,
                              referenceNumber: updatedRef,
                              vendorName: p.vendorName,
                              billNumber: p.billNumber,
                              mode: updatedMode,
                              status: updatedStatus,
                              amount: p.amount,
                              unusedAmount: p.unusedAmount,
                              totalRefunded: p.totalRefunded,
                              notes: updatedNotes,
                              paidThrough: updatedPaidThrough,
                              depositToAccountId: updatedDeposit,
                              amountInWords: p.amountInWords,
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
                  
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                
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
      height: 60,
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
              final isOpen = controller.isOpen;
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                  color: isOpen ? AppTheme.bgHover : Colors.white,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    LucideIcons.moreHorizontal,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => isOpen ? controller.close() : controller.open(),
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
                        const SnackBar(content: Text('Importing from Zoho...')),
                      );
                    },
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text(
                      'Import from Zoho',
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
                onPressed: _loadPaymentsFromDb,
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
    if (_isRefundView) {
      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        color: Colors.white,
        alignment: Alignment.centerLeft,
        child: const Text(
          'Refund',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
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
                      
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selectedPayment.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      
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
          child: Material(
            type: MaterialType.transparency,
            child: Row(
            children: [
              _buildFlatActionTab(LucideIcons.pencil, 'Edit'),
              _buildTabSeparator(),
              _buildFlatActionTab(LucideIcons.mail, 'Send Email'),
              if (_selectedPayment.paymentType.toUpperCase() == 'VENDOR_ADVANCE') ...[
                _buildTabSeparator(),
                InkWell(
                  onTap: _openApplyToBillsDialog,
                  borderRadius: BorderRadius.circular(4),
                  hoverColor: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.fileCheck2,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: AppTheme.space6),
                        Text(
                          'Apply to Bills',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTabSeparator(),
              ] else
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
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    ),
                  );
                },
                menuChildren: [
                  _BulkActionMenuItem(
                    label: 'PDF',
                    icon: LucideIcons.fileText,
                    onTap: () async {
                      _pdfPrintMenuController.close();
                      final bytes = await _generatePdf(_selectedPayment);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: '${_selectedPayment.id}.pdf',
                      );
                    },
                  ),
                  _BulkActionMenuItem(
                    label: 'Print',
                    icon: LucideIcons.printer,
                    onTap: () async {
                      _pdfPrintMenuController.close();
                      final bytes = await _generatePdf(_selectedPayment);
                      await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => bytes,
                      );
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
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: controller.isOpen
                            ? Colors.white
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
                  );
                },
                menuChildren: [
                  if (_selectedPayment.status.toLowerCase() == 'void')
                    _BulkActionMenuItem(
                      label: 'Mark As Paid',
                      icon: LucideIcons.checkCircle2,
                      onTap: () async {
                        _rightMoreMenuController.close();
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
                          if (dbPaymentId != null && dbPaymentId.isNotEmpty) {
                            await supabase
                                .from('payment_made_master')
                                .update({'status': 'paid'})
                                .eq('id', dbPaymentId);
                          }
                          
                          await _loadPaymentsFromDb();
                          
                          if (context.mounted) {
                            ZerpaiToast.success(context, 'Payment marked as Paid');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ZerpaiToast.error(context, 'Failed to mark payment as paid');
                          }
                        }
                      },
                    )
                  else
                    _BulkActionMenuItem(
                      label: 'Void',
                      icon: LucideIcons.ban,
                      onTap: () async {
                        _rightMoreMenuController.close();
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
                          if (dbPaymentId != null && dbPaymentId.isNotEmpty) {
                            await supabase
                                .from('payment_made_master')
                                .update({'status': 'void'})
                                .eq('id', dbPaymentId);
                          }
                          
                          await _loadPaymentsFromDb();
                          
                          if (context.mounted) {
                            ZerpaiToast.success(context, 'Payment marked as Void');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ZerpaiToast.error(context, 'Failed to void payment');
                          }
                        }
                      },
                    ),
                  if (_selectedPayment.paymentType.toUpperCase() == 'VENDOR_ADVANCE')
                    _BulkActionMenuItem(
                      label: 'Apply to Bills',
                      icon: LucideIcons.fileCheck2,
                      onTap: () async {
                        _rightMoreMenuController.close();
                        await _openApplyToBillsDialog();
                      },
                    ),
                  _BulkActionMenuItem(
                    label: 'Refund',
                    icon: LucideIcons.undo,
                    onTap: () {
                      _rightMoreMenuController.close();
                      _openRefundView();
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
        if (label == 'Edit') {
          final orgId = resolveOrgSystemId(context);
          context.go(
            '/$orgId${AppRoutes.paymentsMadeCreate}'
            '?paymentId=${Uri.encodeQueryComponent(_selectedPayment.dbId ?? '')}'
            '&paymentNumber=${Uri.encodeQueryComponent(_selectedPayment.id)}',
          );
        } else if (label == 'Send Email') {
          final orgId = resolveOrgSystemId(context);
          context.go(
            '/$orgId/purchases/payments-made/${_selectedPayment.dbId}/email',
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      hoverColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildRefundLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
        ],
      ),
    );
  }

  Widget _buildRefundDateField() {
    return Container(
      key: _refundDateFieldKey,
      child: CustomTextField(
        controller: _refundDateController,
        readOnly: true,
        height: 38,
        onTap: () async {
          final picked = await ZerpaiDatePicker.show(
            context,
            initialDate: _refundDateValue,
            targetKey: _refundDateFieldKey,
          );
          if (picked == null) return;
          setState(() {
            _refundDateValue = picked;
            _refundDateController.text = DateFormat('dd-MM-yyyy').format(picked);
          });
        },
      ),
    );
  }

  Widget _buildRefundBody(NumberFormat currencyFormat) {
    final balance = _refundBalanceAmount();
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vendor Name',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C89A8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedPayment.vendorName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 118,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _buildRefundLabel(
                                  'Amount',
                                  required: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'INR',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 238,
                              child: CustomTextField(
                                controller: _refundAmountController,
                                height: 38,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 240,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Balance :  '),
                              TextSpan(
                                text: currencyFormat.format(balance),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 170,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildRefundLabel(
                                    'Refunded On',
                                    required: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(child: _buildRefundDateField()),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              SizedBox(
                                width: 170,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildRefundLabel('Reference#'),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: CustomTextField(
                                  controller: _refundReferenceController,
                                  height: 38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 68),
                          Row(
                            children: [
                              SizedBox(
                                width: 170,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildRefundLabel(
                                    'To Account',
                                    required: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final accountsState = ref.watch(
                                      chartOfAccountsProvider,
                                    );
                                    final refundAccountOptions =
                                        _buildRefundAccountOptions(
                                          accountsState.roots,
                                        );
                                    return FormDropdown<_RefundAccountOption>(
                                      value: _findRefundAccountOptionByLabel(
                                        refundAccountOptions,
                                        _refundToAccount,
                                      ),
                                      items: refundAccountOptions,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(
                                          () => _refundToAccount = value.label,
                                        );
                                      },
                                      displayStringForValue: (v) => v.label,
                                      searchStringForValue: (v) => v.label,
                                      hint: 'Select an account',
                                      height: 38,
                                      showSearch: true,
                                      isItemEnabled: (item) => !item.isHeader,
                                      itemBuilder:
                                          (
                                            item,
                                            isSelected,
                                            isHovered,
                                          ) {
                                            if (item.isHeader) {
                                              return Container(
                                                height: 36,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                color: Colors.transparent,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  item.label,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                              );
                                            }

                                            final Color textColor = isHovered
                                                ? Colors.white
                                                : (isSelected
                                                      ? const Color(
                                                          0xFF111827,
                                                        )
                                                      : (item.isBullet
                                                            ? AppTheme
                                                                  .textSecondary
                                                            : AppTheme
                                                                  .textPrimary));
                                            final String displayLabel =
                                                item.isBullet
                                                ? '\u2022 ${item.label}'
                                                : item.label;

                                            return Container(
                                              height: 36,
                                              padding: const EdgeInsets.only(
                                                left: 24,
                                                right: 12,
                                              ),
                                              color: Colors.transparent,
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayLabel,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: textColor,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Icon(
                                                      Icons.check,
                                                      size: 16,
                                                      color: isHovered
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1D4ED8,
                                                            ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 90),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 158,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Payment Mode',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: FormDropdown<String>(
                                  value: _refundPaymentMode,
                                  items: _refundPaymentModeOptions,
                                  onChanged: (value) {
                                    setState(() => _refundPaymentMode = value);
                                  },
                                  height: 38,
                                  showSearch: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 158,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: const [
                                      Text(
                                        'Description of Supply',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      ZTooltip(
                                        message:
                                            'Description of goods or service for which the refund is being made.',
                                        direction: ZTooltipDirection.top,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomTextField(
                                      controller:
                                          _refundSupplyDescriptionController,
                                      maxLines: 3,
                                      minHeight: 58,
                                      height: 58,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Will be displayed on the Refund Voucher',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7C89A8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 158,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: CustomTextField(
                                  controller: _refundDescriptionController,
                                  maxLines: 3,
                                  minHeight: 58,
                                  height: 58,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 42),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: _saveRefund,
                    ),
                    const SizedBox(width: 10),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: _closeRefundView,
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

  Widget _buildRefundHistoryBanner(NumberFormat currencyFormat) {
    return FutureBuilder<List<_PaymentsMadeRefundRow>>(
      future: _refundDetailsFuture,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <_PaymentsMadeRefundRow>[];
        final shouldShow =
            _selectedPayment.totalRefunded > 0 || rows.isNotEmpty;
        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isRefundHistoryExpanded = !_isRefundHistoryExpanded;
                  });
                },
                hoverColor: Colors.transparent,
                child: SizedBox(
                  height: 62,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Refund History',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 15,
                                  height: 15,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    rows.isEmpty && _selectedPayment.totalRefunded > 0
                                        ? '1'
                                        : '${rows.length}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isRefundHistoryExpanded)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 104,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          _isRefundHistoryExpanded
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isRefundHistoryExpanded) ...[
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: Text(
                              'Payment Mode',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text(
                              'Amount Refunded',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (rows.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 180,
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 180,
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  currencyFormat.format(
                                    _selectedPayment.totalRefunded,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        )
                      else
                        ...rows.map(
                          (row) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    row.refundDate.isEmpty ? '-' : row.refundDate,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    row.refundMode.isEmpty ? '-' : row.refundMode,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    currencyFormat.format(row.refundAmount),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _RefundHistoryActionIcon(
                                  icon: LucideIcons.file,
                                  onTap: () => _shareRefundRowPdf(
                                    row,
                                    currencyFormat,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RefundHistoryActionIcon(
                                  icon: LucideIcons.printer,
                                  onTap: () => _printRefundRow(
                                    row,
                                    currencyFormat,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RefundHistoryActionIcon(
                                  icon: LucideIcons.pencil,
                                  onTap: () => _openRefundEditView(row),
                                ),
                                const SizedBox(width: 10),
                                _RefundHistoryActionIcon(
                                  icon: LucideIcons.trash2,
                                  onTap: () => _deleteRefundRow(row),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefundDetailsSection(NumberFormat currencyFormat) {
    return FutureBuilder<List<_PaymentsMadeRefundRow>>(
      future: _refundDetailsFuture,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <_PaymentsMadeRefundRow>[];
        if (_selectedPayment.totalRefunded <= 0 && rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Refund Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF3F4F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Refund Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Refund Number',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Refund Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Account Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Refund Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Expanded(flex: 2, child: Text('-')),
                            const Expanded(flex: 2, child: Text('-')),
                            const Expanded(flex: 2, child: Text('-')),
                            const Expanded(flex: 2, child: Text('-')),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currencyFormat.format(
                                    _selectedPayment.totalRefunded,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...rows.map(
                        (row) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  row.refundDate.isEmpty ? '-' : row.refundDate,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  row.refundNumber.isEmpty ? '-' : row.refundNumber,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  row.refundMode.isEmpty ? '-' : row.refundMode,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  row.accountName.isEmpty ? '-' : row.accountName,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    currencyFormat.format(row.refundAmount),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppliedBillsSection(NumberFormat currencyFormat) {
    return FutureBuilder<List<_PaymentsMadeAppliedBillRow>>(
      future: _loadAppliedBillsForOverview(_selectedPayment.dbId ?? ''),
      builder: (context, snapshot) {
        final rows = (snapshot.data == null || snapshot.data!.isEmpty)
            ? (_selectedPayment.billNumber.trim().isEmpty
                  ? const <_PaymentsMadeAppliedBillRow>[]
                  : <_PaymentsMadeAppliedBillRow>[
                      _PaymentsMadeAppliedBillRow(
                        billNumber: _selectedPayment.billNumber,
                        billDate: _selectedPayment.date,
                        billAmount: _selectedPayment.amount,
                        paymentAmount:
                            _selectedPayment.amount -
                            _selectedPayment.unusedAmount,
                      ),
                    ])
            : snapshot.data!;

        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment for',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
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
                            flex: 24,
                            child: Text(
                              'Bill Number',
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
                              'Bill Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF433F39),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 22,
                            child: Text(
                              'Bill Amount',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF433F39),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 22,
                            child: Text(
                              'Payment Amount',
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
                    ...rows.map(
                      (row) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 15,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE9E4DC),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 24,
                              child: Text(
                                row.billNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 18,
                              child: Text(
                                row.billDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF433F39),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 22,
                              child: Text(
                                currencyFormat.format(row.billAmount),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF433F39),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 22,
                              child: Text(
                                currencyFormat.format(row.paymentAmount),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_PaymentsMadeAppliedBillRow> _resolvedAppliedBillRows(
    List<_PaymentsMadeAppliedBillRow>? rows,
  ) {
    if (rows != null && rows.isNotEmpty) {
      return rows;
    }

    if (_selectedPayment.billNumber.trim().isEmpty) {
      return const <_PaymentsMadeAppliedBillRow>[];
    }

    return <_PaymentsMadeAppliedBillRow>[
      _PaymentsMadeAppliedBillRow(
        billNumber: _selectedPayment.billNumber,
        billDate: _selectedPayment.date,
        billAmount: _selectedPayment.amount,
        paymentAmount: _selectedPayment.amount - _selectedPayment.unusedAmount,
      ),
    ];
  }

  Widget _buildNetOverpaymentTag(NumberFormat currencyFormat) {
    return FutureBuilder<List<_PaymentsMadeAppliedBillRow>>(
      future: _loadAppliedBillsForOverview(_selectedPayment.dbId ?? ''),
      builder: (context, snapshot) {
        final rows = _resolvedAppliedBillRows(snapshot.data);
        final appliedTotal = rows.fold<double>(
          0,
          (sum, row) => sum + row.paymentAmount,
        );
        final netOverpayment =
            _selectedPayment.amount -
            appliedTotal -
            _selectedPayment.totalRefunded;

        if (netOverpayment <= 0) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Over payment: ${currencyFormat.format(netOverpayment)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        );
      },
    );
  }

  Future<List<_PaymentsMadeAppliedBillRow>> _loadAppliedBillsForOverview(
    String paymentId,
  ) async {
    if (paymentId.trim().isEmpty) {
      return const <_PaymentsMadeAppliedBillRow>[];
    }

    final rows = await Supabase.instance.client
        .from('payment_made_bill_allocations')
        .select(
          'bill_amount, allocated_amount, bills(bill_number, bill_date)',
        )
        .eq('payment_made_id', paymentId);

    return (rows as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map((row) {
          final bill =
              row['bills'] is Map<String, dynamic>
              ? row['bills'] as Map<String, dynamic>
              : row['bills'] is Map
              ? Map<String, dynamic>.from(row['bills'] as Map)
              : <String, dynamic>{};
          final billDateRaw = bill['bill_date']?.toString() ?? '';
          final billDate = DateTime.tryParse(billDateRaw);
          return _PaymentsMadeAppliedBillRow(
            billNumber: (bill['bill_number'] ?? '').toString(),
            billDate: billDate == null
                ? ''
                : DateFormat('dd-MM-yyyy').format(billDate),
            billAmount:
                double.tryParse((row['bill_amount'] ?? '0').toString()) ?? 0.0,
            paymentAmount:
                double.tryParse((row['allocated_amount'] ?? '0').toString()) ??
                    0.0,
          );
        })
        .where((row) => row.billNumber.isNotEmpty)
        .toList(growable: false);
  }

  Widget _buildRightBody(NumberFormat currencyFormat) {
    if (_isRefundView) {
      return _buildRefundBody(currencyFormat);
    }
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
                        _buildRefundHistoryBanner(currencyFormat),
                        // White Paper Container
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isDocumentHovered = true),
                          onExit: (_) =>
                              setState(() => _isDocumentHovered = false),
                          child: Container(
                            width: 820,
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
                                  padding: const EdgeInsets.fromLTRB(48, 92, 48, 48),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Header: Logo left | Company name+address right-aligned ──
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Logo box (using Consumer to get orgSettings)
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
                                              final logoUrl = orgSettings?.logoUrl;
                                              
                                              if (logoUrl != null && logoUrl.trim().isNotEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 10),
                                                  child: Container(
                                                    width: 180,
                                                    height: 72,
                                                    padding: const EdgeInsets.all(4),
                                                    alignment: const Alignment(0, 0.18),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey.shade300),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Image.network(
                                                      logoUrl,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        width: 180,
                                                        height: 72,
                                                        color: Colors.black,
                                                        alignment: Alignment.center,
                                                        child: const Text(
                                                          'LOGO',
                                                          style: TextStyle(
                                                            color: Colors.white70,
                                                            fontSize: 12,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              
                                              return Container(
                                                width: 180,
                                                height: 72,
                                                color: Colors.black,
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  'LOGO',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 28),
                                          // Company name + address (grey), left-aligned, close to logo
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedPayment.companyName,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                    
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
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF6B7280,
                                                            ),
                                                          
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                Text(
                                                  'GSTIN ${_selectedPayment.companyGstin}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                    
                                                    height: 1.5,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedPayment.companyPhone,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                    
                                                    height: 1.5,
                                                  ),
                                                ),
                                                Text(
                                                  _selectedPayment.companyEmail,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                    
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 78),
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
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4B5563),
                                            letterSpacing: 2.0,
                                            
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      const SizedBox(height: 24),
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
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Payment Date',
                                                  Text(
                                                    _selectedPayment.date,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
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
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Paid To',
                                                  Text(
                                                    _selectedPayment.vendorName
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color:
                                                          AppTheme.primaryBlue,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Place Of Supply',
                                                  Text(
                                                    _selectedPayment
                                                        .placeOfSupply,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Payment Mode',
                                                  Text(
                                                    _selectedPayment.mode,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Paid Through',
                                                  Text(
                                                    _selectedPayment
                                                        .paidThrough,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                                _buildFieldRow(
                                                  'Amount Paid In Words',
                                                  Text(
                                                    _selectedPayment
                                                        .amountInWords,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                      
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 32),
                                          // ── Right: Amount Paid green card ──
                                          SizedBox(
                                            width: 180,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 22,
                                                    horizontal: 14,
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
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                      
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    currencyFormat.format(
                                                      _selectedPayment.amount,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      // ── Paid To vendor block ──
                                      const Text(
                                        'Paid To',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF6B7280),
                                          
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedPayment.vendorName
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ..._selectedPayment.vendorAddress.map(
                                        (line) => Text(
                                          line,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'GSTIN ${_selectedPayment.vendorGstin}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          
                                          height: 1.5,
                                        ),
                                      ),
                                      if (_selectedPayment.unusedAmount >
                                          0) ...[
                                        const SizedBox(height: 24),
                                        _buildNetOverpaymentTag(
                                          currencyFormat,
                                        ),
                                      ],
                                      _buildAppliedBillsSection(
                                        currencyFormat,
                                      ),
                                      _buildRefundDetailsSection(
                                        currencyFormat,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: PaymentCornerRibbon(
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
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: AnimatedOpacity(
                                    opacity:
                                        (_isDocumentHovered ||
                                            _customizeMenuController.isOpen)
                                        ? 1.0
                                        : 0.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: IgnorePointer(
                                      ignoring:
                                          !(_isDocumentHovered ||
                                              _customizeMenuController.isOpen),
                                      child: MenuAnchor(
                                        controller: _customizeMenuController,
                                        onClose: () => setState(() {}),
                                        style: const MenuStyle(
                                          alignment:
                                              AlignmentDirectional.bottomEnd,
                                          minimumSize: WidgetStatePropertyAll(
                                            Size(200, 0),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                Colors.white,
                                              ),
                                          surfaceTintColor:
                                              WidgetStatePropertyAll(
                                                Colors.white,
                                              ),
                                          padding: WidgetStatePropertyAll(
                                            EdgeInsets.zero,
                                          ),
                                          elevation: WidgetStatePropertyAll(8),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              side: BorderSide(
                                                color: AppTheme.borderColor,
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(4),
                                              ),
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
                                              setState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.successGreen,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    LucideIcons.settings,
                                                    size: 13,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Customize',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                      
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    controller.isOpen
                                                        ? LucideIcons.chevronUp
                                                        : LucideIcons
                                                              .chevronDown,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        menuChildren: [
                                          _BulkActionMenuItem(
                                            label: 'Standard Template',
                                            onTap: () {
                                              _customizeMenuController.close();
                                            },
                                          ),
                                          _BulkActionMenuItem(
                                            label: 'Change Template',
                                            onTap: () {
                                              _customizeMenuController.close();
                                            },
                                          ),
                                          _BulkActionMenuItem(
                                            label: 'Edit Template',
                                            onTap: () {
                                              _customizeMenuController.close();
                                            },
                                          ),
                                          _BulkActionMenuItem(
                                            label: 'Update Logo & Address',
                                            onTap: () {
                                              _customizeMenuController.close();
                                            },
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

  Future<Uint8List> _generatePdf(PaymentMade payment) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 48,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFF0F172A),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'LOGO / LETTERHEAD',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'YOUR COMPANY',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '#${payment.id}',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Date',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        payment.date,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reference Number',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        payment.referenceNumber,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Mode',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        payment.mode,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Amount Paid',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'INR ${payment.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF9FAFB),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Paid To',
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFF6B7280),
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      payment.vendorName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
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

  DateTime _parseDateString(String dateStr) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateStr);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}

// ─── Shared Support UI Components ────────────────────────────────────────────

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

class _RefundHistoryActionIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RefundHistoryActionIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_RefundHistoryActionIcon> createState() =>
      _RefundHistoryActionIconState();
}

class _RefundHistoryActionIconState extends State<_RefundHistoryActionIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered ? AppTheme.primaryBlue : const Color(0xFF4B5563),
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

class ConfigurePaymentNumberPreferencesDialog extends StatefulWidget {
  final String currentLocation;
  final String currentSeries;
  final PaymentNumberPreferences initialPreferences;

  const ConfigurePaymentNumberPreferencesDialog({
    required this.currentLocation,
    required this.currentSeries,
    required this.initialPreferences,
  });

  @override
  State<ConfigurePaymentNumberPreferencesDialog> createState() =>
      _ConfigurePaymentNumberPreferencesDialogState();
}

class _ConfigurePaymentNumberPreferencesDialogState
    extends State<ConfigurePaymentNumberPreferencesDialog> {
  late bool _autoGenerate;
  late final TextEditingController _prefixController;
  late final TextEditingController _manualPrefixController;
  late final TextEditingController _nextNumberController;
  late final TextEditingController _manualPaymentNumberController;
  late bool _restartFiscalYear;

  @override
  void initState() {
    super.initState();
    final preferences = widget.initialPreferences;
    _autoGenerate = preferences.autoGenerate;
    _prefixController = TextEditingController(text: preferences.autoPrefix);
    _manualPrefixController = TextEditingController(
      text: preferences.manualPrefix,
    );
    _nextNumberController = TextEditingController(text: preferences.nextNumber);
    _manualPaymentNumberController = TextEditingController(
      text: preferences.manualPaymentNumber,
    );
    _restartFiscalYear = preferences.restartFiscalYear;
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _manualPrefixController.dispose();
    _nextNumberController.dispose();
    _manualPaymentNumberController.dispose();
    super.dispose();
  }

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
                                  
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                  
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
                                  
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.currentSeries,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                  
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
                        
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Option 1: Auto-generate
                    GestureDetector(
                      onTap: () => setState(() => _autoGenerate = true),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _autoGenerate
                                    ? AppTheme.primaryBlue
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: _autoGenerate
                                ? const DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Auto-generate payment numbers',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                              
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
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: !_autoGenerate
                                    ? AppTheme.primaryBlue
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: !_autoGenerate
                                ? const DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add payment number manually for this payment',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                              
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
                              'autoPrefix': _prefixController.text,
                              'nextNumber': _autoGenerate
                                  ? _nextNumberController.text
                                  : _nextNumberController.text,
                              'manualPrefix': _manualPrefixController.text,
                              'manualPaymentNumber':
                                  _manualPaymentNumberController.text,
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

class _PaymentsMadeRefundRow {
  final String id;
  final String createdAt;
  final String refundDate;
  final String refundNumber;
  final String refundMode;
  final String accountName;
  final String referenceNumber;
  final String description;
  final String supplyDescription;
  final double refundAmount;

  const _PaymentsMadeRefundRow({
    required this.id,
    required this.createdAt,
    required this.refundDate,
    required this.refundNumber,
    required this.refundMode,
    required this.accountName,
    required this.referenceNumber,
    required this.description,
    required this.supplyDescription,
    required this.refundAmount,
  });
}

class _RefundAccountOption {
  final String? id;
  final String label;
  final bool isHeader;
  final bool isBullet;

  const _RefundAccountOption(
    this.label, {
    this.id,
    this.isHeader = false,
    this.isBullet = false,
  });
}

class _PaymentMadeApplyBillRow {
  final String billId;
  final String billNumber;
  final String billDate;
  final String dueDate;
  final String location;
  final double billAmount;
  final double billBalance;
  final String appliedOnDate;
  final TextEditingController amountController;

  _PaymentMadeApplyBillRow({
    required this.billId,
    required this.billNumber,
    required this.billDate,
    required this.dueDate,
    required this.location,
    required this.billAmount,
    required this.billBalance,
    required this.appliedOnDate,
    String initialAmount = '',
  }) : amountController = TextEditingController(text: initialAmount);

  void dispose() => amountController.dispose();
}

class _PaymentsMadeAppliedBillRow {
  final String billNumber;
  final String billDate;
  final double billAmount;
  final double paymentAmount;

  const _PaymentsMadeAppliedBillRow({
    required this.billNumber,
    required this.billDate,
    required this.billAmount,
    required this.paymentAmount,
  });
}

class ApplyPaymentMadeToBillsDialog extends StatefulWidget {
  final PaymentMade payment;

  const ApplyPaymentMadeToBillsDialog({
    super.key,
    required this.payment,
  });

  @override
  State<ApplyPaymentMadeToBillsDialog> createState() =>
      _ApplyPaymentMadeToBillsDialogState();
}

class _ApplyPaymentMadeToBillsDialogState
    extends State<ApplyPaymentMadeToBillsDialog> {
  final NumberFormat _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFmt = DateFormat('dd-MM-yyyy');

  bool _setAppliedOnDate = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String _availableDate = '';
  double _availableCredits = 0.0;
  double _currentExcess = 0.0;
  double _currentAllocated = 0.0;
  String _paymentDbId = '';
  String _vendorId = '';
  String _entityId = '';
  List<_PaymentMadeApplyBillRow> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    for (final bill in _bills) {
      bill.dispose();
    }
    super.dispose();
  }

  double get _totalToApply => _bills.fold<double>(
    0.0,
    (sum, bill) => sum + (double.tryParse(bill.amountController.text) ?? 0.0),
  );

  double get _remainingCredits =>
      (_availableCredits - _totalToApply).clamp(0.0, double.infinity);

  Future<void> _loadBills() async {
    try {
      final supabase = Supabase.instance.client;
      String paymentDbId = widget.payment.dbId?.trim() ?? '';
      _vendorId = widget.payment.vendorId.trim();
      _entityId = widget.payment.entityId.trim();

      if (paymentDbId.isEmpty) {
        final paymentRows = await supabase
            .from('payment_made_master')
            .select(
              'id, vendor_id, entity_id, payment_date, excess_amount, total_allocated',
            )
            .eq('payment_number', widget.payment.id)
            .limit(1);
        if (paymentRows.isEmpty) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
        final row = Map<String, dynamic>.from(paymentRows.first as Map);
        paymentDbId = (row['id'] ?? '').toString();
        _vendorId = (row['vendor_id'] ?? '').toString();
        _entityId = (row['entity_id'] ?? '').toString();
        _currentExcess =
            double.tryParse((row['excess_amount'] ?? '0').toString()) ?? 0.0;
        _currentAllocated =
            double.tryParse((row['total_allocated'] ?? '0').toString()) ?? 0.0;
        final paymentDate = DateTime.tryParse(
          (row['payment_date'] ?? '').toString(),
        );
        _availableDate = _dateFmt.format(paymentDate ?? DateTime.now());
      } else {
        final paymentRow = await supabase
            .from('payment_made_master')
            .select(
              'id, vendor_id, entity_id, payment_date, excess_amount, total_allocated',
            )
            .eq('id', paymentDbId)
            .limit(1)
            .maybeSingle();
        if (paymentRow == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
        final row = Map<String, dynamic>.from(paymentRow as Map);
        _vendorId = (row['vendor_id'] ?? '').toString();
        _entityId = (row['entity_id'] ?? '').toString();
        _currentExcess =
            double.tryParse((row['excess_amount'] ?? '0').toString()) ?? 0.0;
        _currentAllocated =
            double.tryParse((row['total_allocated'] ?? '0').toString()) ?? 0.0;
        final paymentDate = DateTime.tryParse(
          (row['payment_date'] ?? '').toString(),
        );
        _availableDate = _dateFmt.format(paymentDate ?? DateTime.now());
      }

      _paymentDbId = paymentDbId;
      _availableCredits = _currentExcess;

      if (_paymentDbId.isEmpty || _vendorId.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      dynamic billsQuery = supabase
          .from('bills')
          .select(
            'id, bill_number, bill_date, due_date, grand_total, status, is_delete',
          )
          .eq('vendor_id', _vendorId)
          .eq('is_delete', false);
      if (_entityId.isNotEmpty) {
        billsQuery = billsQuery.eq('entity_id', _entityId);
      }
      final billRows = await billsQuery.order('bill_date', ascending: false);

      final billMaps = (billRows as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .where((row) => (row['id'] ?? '').toString().isNotEmpty)
          .toList(growable: false);

      final billIds = billMaps
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final allocatedByBill = <String, double>{};
      if (billIds.isNotEmpty) {
        final allocationRows = await supabase
            .from('payment_made_bill_allocations')
            .select('bill_id, allocated_amount')
            .inFilter('bill_id', billIds);

        for (final raw in allocationRows as List) {
          final row = Map<String, dynamic>.from(raw as Map);
          final billId = (row['bill_id'] ?? '').toString();
          final allocated =
              double.tryParse((row['allocated_amount'] ?? '0').toString()) ??
                  0.0;
          allocatedByBill[billId] = (allocatedByBill[billId] ?? 0.0) + allocated;
        }
      }

      final loadedBills = billMaps.map((row) {
        final billId = (row['id'] ?? '').toString();
        final grandTotal =
            double.tryParse((row['grand_total'] ?? '0').toString()) ?? 0.0;
        final billBalance = (grandTotal - (allocatedByBill[billId] ?? 0.0))
            .clamp(0.0, double.infinity);
        final billDate = DateTime.tryParse((row['bill_date'] ?? '').toString());
        final dueDate = DateTime.tryParse((row['due_date'] ?? '').toString());
        return _PaymentMadeApplyBillRow(
          billId: billId,
          billNumber: (row['bill_number'] ?? '').toString(),
          billDate: _dateFmt.format(billDate ?? DateTime.now()),
          dueDate: dueDate == null ? '-' : _dateFmt.format(dueDate),
          location: 'ZABNIX PRIVATE LIMITED',
          billAmount: grandTotal,
          billBalance: billBalance,
          appliedOnDate: _availableDate,
        );
      }).where((row) => row.billBalance > 0).toList(growable: false);

      for (final bill in loadedBills) {
        bill.amountController.addListener(() => setState(() {}));
      }

      if (!mounted) return;
      setState(() {
        _bills = loadedBills;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ZerpaiToast.error(context, 'Failed to load bills: $e');
    }
  }

  Future<void> _applyToBills() async {
    if (_isSaving) return;

    final selectedRows = _bills.where((bill) {
      final amount = double.tryParse(bill.amountController.text.trim()) ?? 0.0;
      return amount > 0.0;
    }).toList(growable: false);

    if (selectedRows.isEmpty) {
      ZerpaiToast.error(context, 'Enter amount to apply for at least one bill.');
      return;
    }

    if (_totalToApply > _availableCredits + 0.0001) {
      ZerpaiToast.error(context, 'Applied amount exceeds available credits.');
      return;
    }

    for (final row in selectedRows) {
      final amount = double.tryParse(row.amountController.text.trim()) ?? 0.0;
      if (amount > row.billBalance + 0.0001) {
        ZerpaiToast.error(
          context,
          'Applied amount exceeds bill balance for ${row.billNumber}.',
        );
        return;
      }
    }

    try {
      setState(() => _isSaving = true);
      final supabase = Supabase.instance.client;

      final insertRows = selectedRows.map((row) {
        final amount = double.tryParse(row.amountController.text.trim()) ?? 0.0;
        return <String, dynamic>{
          'payment_made_id': _paymentDbId,
          'bill_id': row.billId,
          'bill_amount': row.billAmount,
          'amount_due': row.billBalance,
          'allocated_amount': amount,
          'payment_date': _setAppliedOnDate
              ? DateFormat('dd-MM-yyyy')
                    .parse(row.appliedOnDate)
                    .toIso8601String()
                    .split('T')[0]
              : null,
        };
      }).toList(growable: false);

      await supabase.from('payment_made_bill_allocations').insert(insertRows);

      for (final row in selectedRows) {
        final amount = double.tryParse(row.amountController.text.trim()) ?? 0.0;
        final remaining = (row.billBalance - amount).clamp(0.0, double.infinity);
        final nextStatus = remaining <= 0.0001 ? 'paid' : 'partially_paid';
        await supabase
            .from('bills')
            .update({'status': nextStatus})
            .eq('id', row.billId);
      }

      await supabase
          .from('payment_made_master')
          .update({
            'total_allocated': _currentAllocated + _totalToApply,
            'excess_amount': (_currentExcess - _totalToApply).clamp(
              0.0,
              double.infinity,
            ),
          })
          .eq('id', _paymentDbId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to apply bills: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, minWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Apply to Bills - ${widget.payment.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.errorRed,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Bills to Apply',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Set Applied on Date',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const ZTooltip(
                              message:
                                  'The selected payment date will be recorded for applied bills.',
                              child: Icon(
                                LucideIcons.helpCircle,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Switch(
                              value: _setAppliedOnDate,
                              onChanged: (v) =>
                                  setState(() => _setAppliedOnDate = v),
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppTheme.primaryBlue,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: AppTheme.borderLight,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 16),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: 'Available Credits: '),
                                  TextSpan(
                                    text: '₹${_fmt.format(_availableCredits)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (_availableDate.isNotEmpty)
                                    TextSpan(text: ' ($_availableDate)'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Table(
                            border: TableBorder.all(
                              color: AppTheme.borderLight,
                              width: 1,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            columnWidths: {
                              0: const FlexColumnWidth(1.5),
                              1: const FlexColumnWidth(1.4),
                              2: const FlexColumnWidth(2.2),
                              3: const FlexColumnWidth(1.5),
                              4: const FlexColumnWidth(1.5),
                              if (_setAppliedOnDate)
                                5: const FlexColumnWidth(1.6),
                              if (_setAppliedOnDate)
                                6: const FlexColumnWidth(1.6)
                              else
                                5: const FlexColumnWidth(1.6),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: AppTheme.bgLight,
                                ),
                                children: [
                                  _ATBCell(child: _ATBColHeader('BILL#')),
                                  _ATBCell(child: _ATBColHeader('BILL DATE')),
                                  _ATBCell(child: _ATBColHeader('LOCATION')),
                                  _ATBCell(
                                    child: _ATBColHeader(
                                      'BILL AMOUNT',
                                      align: TextAlign.right,
                                    ),
                                  ),
                                  _ATBCell(
                                    child: _ATBColHeader(
                                      'BILL BALANCE',
                                      align: TextAlign.right,
                                    ),
                                  ),
                                  if (_setAppliedOnDate)
                                    _ATBCell(
                                      child: _ATBColHeader('APPLIED ON'),
                                    ),
                                  _ATBCell(
                                    child: _ATBColHeader(
                                      'AMOUNT TO APPLY',
                                      align: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              ..._bills.map((bill) {
                                return TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  children: [
                                    _ATBCell(
                                      child: Text(
                                        bill.billNumber,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    _ATBCell(
                                      child: Text(
                                        bill.billDate,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    _ATBCell(
                                      child: Text(
                                        bill.location,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    _ATBCell(
                                      child: Text(
                                        '₹${_fmt.format(bill.billAmount)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    _ATBCell(
                                      child: Text(
                                        '₹${_fmt.format(bill.billBalance)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    if (_setAppliedOnDate)
                                      _ATBCell(
                                        child: Text(
                                          bill.appliedOnDate,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    _ATBCell(
                                      child: SizedBox(
                                        height: 32,
                                        child: TextField(
                                          controller: bill.amountController,
                                          textAlign: TextAlign.right,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}$'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: AppTheme.borderColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 340,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                _applySummaryRow(
                                  'Applied Amount:',
                                  _fmt.format(_totalToApply),
                                ),
                                const SizedBox(height: 10),
                                _applySummaryRow(
                                  'Remaining Credits:',
                                  _fmt.format(_remainingCredits),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.successGreen),
                      foregroundColor: AppTheme.successGreen,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ZButton.primary(
                    onPressed: _isSaving ? null : _applyToBills,
                    label: _isSaving ? 'Applying...' : 'Apply',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applySummaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ATBCell extends StatelessWidget {
  final Widget child;

  const _ATBCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: child,
    );
  }
}

class _ATBColHeader extends StatelessWidget {
  final String label;
  final TextAlign align;

  const _ATBColHeader(this.label, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: align,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.4,
      ),
    );
  }
}

class PaymentsMadeEmailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentsMadeEmailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentsMadeEmailScreen> createState() =>
      _PaymentsMadeEmailScreenState();
}

class _PaymentsMadeEmailScreenState
    extends ConsumerState<PaymentsMadeEmailScreen> {
  bool _isLoading = true;
  pm_model.PaymentMade? _payment;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    try {
      final repository = ref.read(pm_prov.paymentsMadeRepositoryProvider);
      final payment = await repository.getPaymentMade(widget.paymentId);
      if (payment != null) {
        final orgSettings = ref.read(orgSettingsProvider).asData?.value;
        final orgName = orgSettings?.name ?? '';
        final user = ref.read(authUserProvider);
        final orgEmail = orgSettings?.email ?? user?.email ?? 'info@zerpai.com';

        final vendorName = payment.vendorName ?? 'Vendor';
        String vendorEmail = 'vendor@example.com';

        try {
          final vendorRepo = ref.read(vendorRepositoryProvider);
          // ignore: invalid_use_of_protected_member
          final vendor = await vendorRepo.getVendorById(payment.vendorId);
          if (vendor != null && vendor.email != null && vendor.email!.isNotEmpty) {
            vendorEmail = vendor.email!;
          }
        } catch (e) {
          AppLogger.error('Failed to load vendor email', error: e, module: 'purchases');
        }

        _fromCtrl.text = '$orgName <$orgEmail>';
        _toCtrl.text = '$vendorName <$vendorEmail>';
        _subjectCtrl.text =
            'Payment Receipt from $orgName (Payment #: ${payment.paymentNumber})';

        final dateStr = DateFormat('dd-MM-yyyy').format(payment.paymentDate);
        final amountStr = NumberFormat(
          '#,##,##0.00',
          'en_IN',
        ).format(payment.paymentAmount);

        _bodyCtrl.text =
            '''Dear $vendorName,

Please find the payment receipt (${payment.paymentNumber}) attached with this email.

An overview of the payment receipt is available below:
----------------------------------------------------------------------------------------------------

Payment Receipt # : ${payment.paymentNumber}

----------------------------------------------------------------------------------------------------

Payment Date : $dateStr
Amount : ₹$amountStr(in INR)

----------------------------------------------------------------------------------------------------

Thank you for your business. We look forward to working with you again.

Regards,
$orgName''';

        setState(() {
          _payment = payment;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ZerpaiToast.error(context, 'Payment made not found');
          context.pop();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error loading payment for email',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load payment data: $e');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final payment = _payment!;
    final vendorName = payment.vendorName ?? 'Vendor';

    return EmailComposerScreen(
      title: 'Email To $vendorName',
      initialFrom: _fromCtrl.text,
      initialTo: _toCtrl.text,
      initialSubject: _subjectCtrl.text,
      initialBody: _bodyCtrl.text,
      attachmentName: payment.paymentNumber,
      attachmentLabel: 'Attach Payment Receipt PDF',
      onCancel: () async {
        if (context.mounted) {
          final orgId = resolveOrgSystemId(context);
          context.go('/$orgId/purchases/payments-made');
        }
      },
      onSend: (from, to, subject, body, attachPdf) async {
        if (context.mounted) {
          ZerpaiToast.success(context, 'Email sent successfully');
          final orgId = resolveOrgSystemId(context);
          context.go('/$orgId/purchases/payments-made');
        }
      },
    );
  }
}

