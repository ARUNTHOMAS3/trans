import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/email_composer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/widgets/payment_corner_ribbon.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/modules/sales/quotations/presentation/providers/sales_quotes_refresh_provider.dart';

const Color _pdfRuleColor = Color(0xFFB8B8B8);
const String _pdfFontFamily = 'Times New Roman';

double _quoteNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _quoteCustomerDisplayName(dynamic customer) {
  if (customer is! Map) return '-';
  final rawName =
      customer['display_name'] ?? customer['displayName'] ?? customer['name'];
  final name = rawName?.toString().trim() ?? '';
  return name.isNotEmpty ? name : '-';
}

String _quoteCustomerEmail(dynamic customer) {
  if (customer is! Map) return '';
  return customer['email']?.toString() ?? '';
}

String _quoteFirstNonEmptyField(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _quoteAddressOrDash(List<String?> parts) {
  final cleaned = parts
      .map((part) => part?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return '-';
  return cleaned.join(', ');
}

List<String> _quoteAddressLines(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == '-') {
    return const <String>['-'];
  }
  final normalized = trimmed.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rawLines = normalized.contains('\n')
      ? normalized.split('\n')
      : normalized.split(',');
  final lines = rawLines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  return lines.isEmpty ? const <String>['-'] : lines;
}

List<String> _orgProfileLines(dynamic org) {
  if (org == null) return const <String>[];
  final lines = <String>[
    org.attention?.toString().trim() ?? '',
    [
      org.place?.toString().trim() ?? '',
      org.city?.toString().trim() ?? '',
      org.pincode?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' '),
    org.country?.toString().trim() ?? '',
    org.companyIdentityLine?.toString().trim() ?? '',
    org.phone?.toString().trim() ?? '',
    org.email?.toString().trim() ?? '',
  ].where((line) => line.isNotEmpty).toList();
  return lines;
}

Map<String, dynamic> _quoteMergeCustomerAddresses(
  Map<String, dynamic> customer,
  List<Map<String, dynamic>> addresses,
) {
  if (addresses.isEmpty) return customer;
  final merged = Map<String, dynamic>.from(customer);
  merged['customer_addresses'] = addresses;
  merged['addresses'] = addresses;

  Map<String, dynamic>? billing;
  Map<String, dynamic>? shipping;
  for (final address in addresses) {
    final addressType = (address['address_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (billing == null &&
        (address['is_default_billing'] == true || addressType == 'billing')) {
      billing = address;
    }
    if (shipping == null &&
        (address['is_default_shipping'] == true || addressType == 'shipping')) {
      shipping = address;
    }
  }
  billing ??= addresses.first;
  shipping ??= billing;

  void applyAddress(Map<String, dynamic>? raw, {required bool isBilling}) {
    if (raw == null) return;
    final prefix = isBilling ? 'billing' : 'shipping';
    merged['${prefix}_address_street'] = raw['address_street'];
    merged['${prefix}_address_street1'] = raw['address_street'];
    merged['${prefix}_address_place'] = raw['address_place'];
    merged['${prefix}_address_street2'] = raw['address_place'];
    merged['${prefix}_address_city'] = raw['city'];
    merged['${prefix}_address_state'] = raw['state'];
    merged['${prefix}_address_state_id'] = raw['state'];
    merged['${prefix}_address_zip'] = raw['pincode'];
    merged['${prefix}_address_country'] = raw['country_region'];
    merged['${prefix}_address_country_id'] = raw['country_region'];
    merged['${prefix}_address_phone'] = raw['phone'];
    merged['${prefix}_address'] = _quoteAddressOrDash([
      raw['address_street']?.toString(),
      raw['address_place']?.toString(),
      raw['city']?.toString(),
      raw['state']?.toString(),
      raw['pincode']?.toString(),
      raw['country_region']?.toString(),
    ]);
  }

  applyAddress(billing, isBilling: true);
  applyAddress(shipping, isBilling: false);
  return merged;
}

String _quoteAdditionalAddressByType(
  List<Map<String, dynamic>> addresses,
  String type,
) {
  for (final raw in addresses) {
    final addressType =
        (raw['address_type'] ?? raw['type'] ?? raw['addressType'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final isDefault = type == 'billing'
        ? raw['is_default_billing'] == true
        : raw['is_default_shipping'] == true;
    if (addressType != type && !isDefault) {
      continue;
    }
    final formatted = _quoteAddressOrDash([
      (raw['street1'] ??
              raw['billing_address_street'] ??
              raw['shipping_address_street'])
          ?.toString(),
      (raw['street2'] ??
              raw['billing_address_place'] ??
              raw['shipping_address_place'])
          ?.toString(),
      (raw['city'] ??
              raw['billing_address_city'] ??
              raw['shipping_address_city'])
          ?.toString(),
      (raw['state'] ?? raw['billing_state'] ?? raw['shipping_state'])
          ?.toString(),
      (raw['zip'] ?? raw['billing_pincode'] ?? raw['shipping_pincode'])
          ?.toString(),
      (raw['country'] ??
              raw['billing_country_region'] ??
              raw['shipping_country_region'])
          ?.toString(),
    ]);
    if (formatted != '-') return formatted;
  }
  return '-';
}

String _quoteCustomerBillingAddress(dynamic customer) {
  if (customer is! Map<String, dynamic>) return '-';
  final fullAddress = _quoteFirstNonEmptyField(customer, const [
    'billing_address',
    'billingAddress',
  ]);
  if (fullAddress.isNotEmpty) return fullAddress;
  final parsed = SalesCustomer.fromJson(customer);
  if (parsed.fullBillingAddress != 'N/A') {
    return parsed.fullBillingAddress.replaceAll('\n', ', ');
  }
  return _quoteAdditionalAddressByType(parsed.additionalAddresses, 'billing');
}

String _quoteCustomerShippingAddress(dynamic customer) {
  if (customer is! Map<String, dynamic>) return '-';
  final fullAddress = _quoteFirstNonEmptyField(customer, const [
    'shipping_address',
    'shippingAddress',
  ]);
  if (fullAddress.isNotEmpty) return fullAddress;
  final parsed = SalesCustomer.fromJson(customer);
  if (parsed.fullShippingAddress != 'N/A') {
    return parsed.fullShippingAddress.replaceAll('\n', ', ');
  }
  return _quoteAdditionalAddressByType(parsed.additionalAddresses, 'shipping');
}

String _quoteRecordBillingAddress(Map<String, dynamic> quote) {
  return _quoteAddressOrDash([
    _quoteFirstNonEmptyField(quote, const ['billing_address']),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_street1',
      'billing_address_street',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_street2',
      'billing_address_place',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_city',
      'billing_city',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_state_id',
      'billing_address_state',
      'billing_state',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_zip',
      'billing_pincode',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'billing_address_country_id',
      'billing_address_country',
      'billing_country_region',
    ]),
  ]);
}

String _quoteRecordShippingAddress(Map<String, dynamic> quote) {
  return _quoteAddressOrDash([
    _quoteFirstNonEmptyField(quote, const ['shipping_address']),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_street1',
      'shipping_address_street',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_street2',
      'shipping_address_place',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_city',
      'shipping_city',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_state_id',
      'shipping_address_state',
      'shipping_state',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_zip',
      'shipping_pincode',
    ]),
    _quoteFirstNonEmptyField(quote, const [
      'shipping_address_country_id',
      'shipping_address_country',
      'shipping_country_region',
    ]),
  ]);
}

String _quoteSalesCustomerAddressOrDash(List<String?> parts) {
  final cleaned = parts
      .map((part) => part?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
  if (cleaned.isEmpty) return '-';
  return cleaned.join(', ');
}

String _salesCustomerBillingAddress(SalesCustomer? customer) {
  if (customer == null) return '-';
  return _quoteSalesCustomerAddressOrDash([
    customer.billingAddressStreet1,
    customer.billingAddressStreet2,
    customer.billingAddressCity,
    customer.billingAddressStateId,
    customer.billingAddressZip,
    customer.billingAddressCountryId,
  ]);
}

String _salesCustomerShippingAddress(SalesCustomer? customer) {
  if (customer == null) return '-';
  return _quoteSalesCustomerAddressOrDash([
    customer.shippingAddressStreet1,
    customer.shippingAddressStreet2,
    customer.shippingAddressCity,
    customer.shippingAddressStateId,
    customer.shippingAddressZip,
    customer.shippingAddressCountryId,
  ]);
}

class SalesQuotationOverviewPage extends ConsumerStatefulWidget {
  final String quoteId;

  const SalesQuotationOverviewPage({super.key, required this.quoteId});

  @override
  ConsumerState<SalesQuotationOverviewPage> createState() =>
      _SalesQuotationOverviewPageState();
}

class _SalesQuotationOverviewPageState
    extends ConsumerState<SalesQuotationOverviewPage> {
  int _mainTabIndex = 0;
  int _viewTabIndex = 0;
  int _quotePreferencesTabIndex = 0;
  bool _isLoading = true;
  bool _showQuotePreferencesPanel = false;
  bool _showCommentsPanel = false;
  bool _allowEditingAcceptedQuotes = false;
  bool _allowCustomerAcceptance = false;
  int _acceptedQuoteConversionMode = 0;
  bool _hideZeroValueLineItems = false;
  bool _retainCustomerNotes = true;
  bool _retainTermsConditions = true;
  bool _retainAddress = true;
  final MenuController _viewMenuController = MenuController();
  final MenuController _customizeMenuController = MenuController();
  final GlobalKey _pageStackKey = GlobalKey();
  final GlobalKey _attachmentButtonKey = GlobalKey();
  bool _showAttachmentOverlay = false;
  bool _pdfHovered = false;
  String _selectedView = 'All Quotes';
  bool _viewIsStarred = false;
  String _overviewSortByField = 'date';
  bool _overviewSortAscending = false;
  String _selectedTemplate = 'Standard Template';
  // ignore: unused_field
  bool _isLoadingAttachments = false;
  bool _showAttachmentsInPortal = false;
  // ignore: unused_field
  List<Map<String, dynamic>> _quoteAttachments = const <Map<String, dynamic>>[];
  final Map<String, List<Map<String, dynamic>>> _quoteAttachmentsById =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, List<Map<String, dynamic>>> _quoteCommentsById =
      <String, List<Map<String, dynamic>>>{};
  final TextEditingController _quotePreferencesTermsCtrl =
      TextEditingController();
  final TextEditingController _quotePreferencesNotesCtrl =
      TextEditingController();
  final TextEditingController _commentDraftCtrl = TextEditingController();

  void _notifyQuoteReportRefresh() {
    ref.read(salesQuotationRefreshTickProvider.notifier).state++;
  }

  final List<_QuoteOverviewRecord> _quotes = <_QuoteOverviewRecord>[];

  _QuoteOverviewRecord get _selectedQuote {
    return _quotes.firstWhere(
      (quote) => quote.dbId == widget.quoteId || quote.id == widget.quoteId,
      orElse: () => const _QuoteOverviewRecord(
        id: '',
        customerName: '',
        date: '',
        status: '',
        amount: '',
        location: '',
        placeOfSupply: '',
        salesperson: '',
        billingAddress: '-',
        shippingAddress: '-',
        customerEmail: '',
        notes: '-',
        terms: '-',
        subTotal: '',
        cgst: '',
        sgst: '',
        adjustment: '0.00',
        roundOff: '',
        total: '',
        statusLabel: '',
        items: <_QuoteItem>[],
        activities: <_QuoteActivity>[],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  @override
  void dispose() {
    _quotePreferencesTermsCtrl.dispose();
    _quotePreferencesNotesCtrl.dispose();
    _commentDraftCtrl.dispose();
    super.dispose();
  }

  void _openQuotePreferencesPanel() {
    final selected = _selectedQuote;
    setState(() {
      _showAttachmentOverlay = false;
      _showQuotePreferencesPanel = true;
      _quotePreferencesTabIndex = 0;
      _quotePreferencesTermsCtrl.text = selected.terms.trim() == '-'
          ? ''
          : selected.terms;
      _quotePreferencesNotesCtrl.text = selected.notes == '-'
          ? ''
          : selected.notes;
    });
  }

  void _closeQuotePreferencesPanel() {
    setState(() {
      _showQuotePreferencesPanel = false;
    });
  }

  void _openCommentsPanel() {
    setState(() {
      _showAttachmentOverlay = false;
      _showCommentsPanel = true;
    });
  }

  void _closeCommentsPanel() {
    setState(() {
      _showCommentsPanel = false;
    });
  }

  void _closeAttachmentOverlay() {
    _showAttachmentOverlay = false;
  }

  void _toggleAttachmentOverlay(_QuoteOverviewRecord quote) {
    setState(() {
      _showAttachmentOverlay = !_showAttachmentOverlay;
    });
  }

  Rect _attachmentButtonRect() {
    final stackContext = _pageStackKey.currentContext;
    final buttonContext = _attachmentButtonKey.currentContext;
    if (stackContext == null || buttonContext == null) {
      return const Rect.fromLTWH(0, 0, 0, 0);
    }
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (stackBox == null || buttonBox == null) {
      return const Rect.fromLTWH(0, 0, 0, 0);
    }
    final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: stackBox);
    return topLeft & buttonBox.size;
  }

  Widget _buildAttachmentOverlay(_QuoteOverviewRecord quote) {
    final selectedAttachmentRows =
        _quoteAttachmentsById[(quote.dbId ?? '').trim()] ??
        const <Map<String, dynamic>>[];
    final buttonRect = _attachmentButtonRect();
    final popupLeft = (buttonRect.left - 180).clamp(12.0, double.infinity);
    final popupTop = buttonRect.bottom + 8;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showAttachmentOverlay = false),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: popupLeft,
            top: popupTop,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                setState(() => _showAttachmentOverlay = false),
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
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    if (selectedAttachmentRows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'No Files Attached',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: selectedAttachmentRows.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                          itemBuilder: (context, index) {
                            final attachment = selectedAttachmentRows[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAttachmentTypeIcon(attachment),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          attachment['file_name']?.toString() ??
                                              'Attachment',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'File Size: ${_formatAttachmentSize(attachment['file_size'])}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Display attachments in Customer Portal\nand emails',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _showAttachmentsInPortal,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF34C759),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFD0D5DD),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                setState(() {
                                  _showAttachmentsInPortal = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: DottedBorder(
                        color: const Color(0xFFD0D5DD),
                        strokeWidth: 1,
                        dashPattern: const [4, 3],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(8),
                        child: InkWell(
                          onTap: () => _uploadQuoteAttachments(quote),
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 58,
                            width: double.infinity,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    LucideIcons.upload,
                                    size: 18,
                                    color: Color(0xFF2563EB),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Upload your Files',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Center(
                        child: Text(
                          'You can upload a maximum of 5 files, 10MB each',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                      ),
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

  List<Map<String, dynamic>> _commentsFor(_QuoteOverviewRecord quote) {
    return _quoteCommentsById.putIfAbsent(
      quote.dbId ?? quote.id,
      () => <Map<String, dynamic>>[],
    );
  }

  void _addComment(_QuoteOverviewRecord quote) {
    final message = _commentDraftCtrl.text.trim();
    if (message.isEmpty) {
      return;
    }
    final user = ref.read(authUserProvider);
    final author = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : ((user?.email.trim().isNotEmpty ?? false)
              ? user!.email.trim().split('@').first
              : 'User');

    setState(() {
      _commentsFor(quote).insert(0, {
        'author': author,
        'date': DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
        'message': message,
      });
      _commentDraftCtrl.clear();
    });

    ZerpaiToast.success(context, 'Comments added.');
  }

  void _deleteComment(_QuoteOverviewRecord quote, int index) {
    setState(() {
      _commentsFor(quote).removeAt(index);
    });
  }

  void _closeOverviewToReportPage() {
    setState(() {
      _showAttachmentOverlay = false;
      _showQuotePreferencesPanel = false;
      _showCommentsPanel = false;
    });
    context.go(AppRoutes.salesQuotations);
  }

  Future<void> _loadQuoteAttachments(_QuoteOverviewRecord quote) async {
    final quotationId = (quote.dbId ?? '').trim();
    final cached = quotationId.isNotEmpty
        ? _quoteAttachmentsById[quotationId]
        : null;
    if (!mounted) return;
    setState(() {
      _quoteAttachments = cached ?? const <Map<String, dynamic>>[];
      _isLoadingAttachments = false;
    });
  }

  String _quotationAttachmentMimeType(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') {
      return 'application/pdf';
    }
    if (ext == 'jpg' || ext == 'jpeg') {
      return 'image/jpeg';
    }
    if (ext == 'png') {
      return 'image/png';
    }
    return 'application/octet-stream';
  }

  String _formatAttachmentSize(dynamic bytesValue) {
    final bytes = bytesValue is num
        ? bytesValue.toDouble()
        : double.tryParse(bytesValue?.toString() ?? '') ?? 0;
    if (bytes <= 0) return '0 KB';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  Widget _buildAttachmentTypeIcon(Map<String, dynamic> attachment) {
    final fileName = attachment['file_name']?.toString().toLowerCase() ?? '';
    final mimeType = attachment['mime_type']?.toString().toLowerCase() ?? '';
    final isPdf = mimeType.contains('pdf') || fileName.endsWith('.pdf');

    return Icon(
      isPdf ? Icons.picture_as_pdf_rounded : LucideIcons.file,
      size: 22,
      color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
    );
  }

  Future<void> _uploadQuoteAttachments(_QuoteOverviewRecord quote) async {
    final quotationId = await _resolveExistingQuotationDbId(quote);
    if (quotationId == null || quotationId.isEmpty) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        'Quote record not found for attachment upload.',
      );
      return;
    }

    final existingCount =
        _quoteAttachmentsById[quotationId]?.length ?? quote.attachmentCount;
    final remainingSlots = 5 - existingCount;
    if (remainingSlots <= 0) {
      if (!mounted) return;
      ZerpaiToast.info(context, 'Maximum 5 attachments already added.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedFiles = result.files.take(remainingSlots).toList();
    final oversizeFile = selectedFiles.cast<PlatformFile?>().firstWhere(
      (file) => (file?.size ?? 0) > 10 * 1024 * 1024,
      orElse: () => null,
    );
    if (oversizeFile != null) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        '${oversizeFile.name} exceeds 10MB. Please upload a smaller file.',
      );
      return;
    }

    setState(() => _isLoadingAttachments = true);

    try {
      final storage = StorageService();
      final supabase = Supabase.instance.client;
      final user = ref.read(authUserProvider);
      final List<Map<String, dynamic>> attachmentRows = [];

      for (final file in selectedFiles) {
        if (file.bytes == null) {
          continue;
        }
        final fileUrl = await storage.uploadQuotationAttachment(file);
        if (fileUrl == null || fileUrl.isEmpty) {
          continue;
        }

        attachmentRows.add({
          'quotation_id': quotationId,
          'file_name': file.name,
          'storage_path': fileUrl,
          'mime_type': _quotationAttachmentMimeType(file),
          'file_size': file.size,
          'uploaded_by': user?.id,
        });
      }

      if (attachmentRows.isEmpty) {
        throw Exception('Upload failed for selected file(s).');
      }

      await supabase.from('sales_quotation_attachments').insert(attachmentRows);
      final cachedRows = List<Map<String, dynamic>>.from(
        _quoteAttachmentsById[quotationId] ?? const <Map<String, dynamic>>[],
      )..insertAll(0, attachmentRows);
      _quoteAttachmentsById[quotationId] = cachedRows;
      _quoteAttachments = cachedRows;
      final selectedIndex = _quotes.indexWhere(
        (entry) => (entry.dbId ?? '').trim() == quotationId,
      );
      if (selectedIndex != -1) {
        final current = _quotes[selectedIndex];
        _quotes[selectedIndex] = _QuoteOverviewRecord(
          dbId: current.dbId,
          id: current.id,
          customerName: current.customerName,
          date: current.date,
          status: current.status,
          amount: current.amount,
          location: current.location,
          placeOfSupply: current.placeOfSupply,
          salesperson: current.salesperson,
          billingAddress: current.billingAddress,
          shippingAddress: current.shippingAddress,
          customerEmail: current.customerEmail,
          notes: current.notes,
          terms: current.terms,
          subTotal: current.subTotal,
          cgst: current.cgst,
          sgst: current.sgst,
          adjustment: current.adjustment,
          roundOff: current.roundOff,
          total: current.total,
          attachmentCount: cachedRows.length,
          statusLabel: current.statusLabel,
          items: current.items,
          activities: current.activities,
          clonePayload: current.clonePayload,
        );
      }
      await _loadQuoteAttachments(quote);

      if (!mounted) return;
      final uploadedCount = attachmentRows.length;
      final ignoredCount = result.files.length - selectedFiles.length;
      final message = ignoredCount > 0
          ? '$uploadedCount attachment(s) uploaded. $ignoredCount skipped due to max 5 files.'
          : '$uploadedCount attachment(s) uploaded successfully.';
      ZerpaiToast.success(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAttachments = false);
      ZerpaiToast.error(
        context,
        'Failed to upload attachments: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<String?> _resolveExistingQuotationDbId(
    _QuoteOverviewRecord quote,
  ) async {
    final directDbId = quote.dbId?.trim() ?? '';
    if (directDbId.isNotEmpty) {
      return directDbId;
    }

    final supabase = Supabase.instance.client;
    final candidateIds = <String>{
      if (quote.id.trim().isNotEmpty) quote.id.trim(),
    };

    for (final candidate in candidateIds) {
      try {
        final byId = await supabase
            .from('sales_quotations')
            .select('id')
            .eq('id', candidate)
            .maybeSingle();
        if (byId != null) {
          return byId['id']?.toString();
        }
      } catch (_) {}
    }

    try {
      final byNumber = await supabase
          .from('sales_quotations')
          .select('id')
          .eq('quotation_number', quote.id.trim())
          .maybeSingle();
      if (byNumber != null) {
        return byNumber['id']?.toString();
      }
    } catch (_) {}

    return null;
  }

  Future<void> _updateQuoteStatusWithActivity({
    required _QuoteOverviewRecord quote,
    required String status,
    required String action,
    required String description,
  }) async {
    final supabase = Supabase.instance.client;
    final resolvedDbId = await _resolveExistingQuotationDbId(quote);
    if (resolvedDbId == null || resolvedDbId.isEmpty) {
      throw Exception(
        'Quote record not found in sales_quotations for ${quote.id}.',
      );
    }

    await supabase
        .from('sales_quotations')
        .update({'status': status})
        .eq('id', resolvedDbId);

    final verifiedQuote = await supabase
        .from('sales_quotations')
        .select('id')
        .eq('id', resolvedDbId)
        .maybeSingle();
    if (verifiedQuote == null) {
      throw Exception(
        'Quote record missing after status update for ${quote.id}.',
      );
    }

    final user = ref.read(authUserProvider);
    await supabase.from('sales_quotation_activity').insert({
      'quotation_id': resolvedDbId,
      'action': action,
      'description': description,
      'performed_by': user?.id,
    });
  }

  Future<void> _deleteQuoteFromDb(_QuoteOverviewRecord quote) async {
    final supabase = Supabase.instance.client;
    final resolvedDbId = await _resolveExistingQuotationDbId(quote);
    if (resolvedDbId == null || resolvedDbId.isEmpty) {
      throw Exception(
        'Quote record not found in sales_quotations for ${quote.id}.',
      );
    }

    await supabase
        .from('sales_quotation_attachments')
        .delete()
        .eq('quotation_id', resolvedDbId);
    await supabase
        .from('sales_quotation_activity')
        .delete()
        .eq('quotation_id', resolvedDbId);
    await supabase
        .from('sales_quotation_items')
        .delete()
        .eq('quotation_id', resolvedDbId);
    await supabase.from('sales_quotations').delete().eq('id', resolvedDbId);
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = ref.read(authUserProvider);
      final quotesResponse = await supabase
          .from('sales_quotations')
          .select(
            '*, '
            'salesperson_id, created_at, '
            'salesperson:users!salesperson_id(full_name, email), '
            'customer:customers(*)',
          )
          .order('created_at', ascending: false);
      final quotes = (quotesResponse as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final customerIds = quotes
          .map((q) => q['customer_id']?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final Map<String, Map<String, dynamic>> customersById =
          <String, Map<String, dynamic>>{};
      final Map<String, List<Map<String, dynamic>>>
      customerAddressesByCustomerId = <String, List<Map<String, dynamic>>>{};
      if (customerIds.isNotEmpty) {
        try {
          final customersResponse = await supabase
              .from('customers')
              .select('*')
              .inFilter('id', customerIds);
          for (final row in (customersResponse as List<dynamic>)) {
            final customerMap = Map<String, dynamic>.from(row as Map);
            final customerId = customerMap['id']?.toString().trim() ?? '';
            if (customerId.isNotEmpty) {
              customersById[customerId] = customerMap;
            }
          }
        } catch (e) {
          debugPrint('Error fetching customers for quote overview: $e');
        }
        try {
          final addressesResponse = await supabase
              .from('customer_addresses')
              .select(
                'customer_id, address_type, address_street, address_place, city, '
                'state, pincode, country_region, phone, '
                'is_default_billing, is_default_shipping, is_active',
              )
              .inFilter('customer_id', customerIds)
              .eq('is_active', true);
          for (final row in (addressesResponse as List<dynamic>)) {
            final addressMap = Map<String, dynamic>.from(row as Map);
            final customerId =
                addressMap['customer_id']?.toString().trim() ?? '';
            if (customerId.isEmpty) continue;
            customerAddressesByCustomerId
                .putIfAbsent(customerId, () => <Map<String, dynamic>>[])
                .add(addressMap);
          }
        } catch (e) {
          debugPrint(
            'Error fetching customer addresses for quote overview: $e',
          );
        }
      }

      List<dynamic> providerQuotes = const <dynamic>[];
      try {
        providerQuotes = await ref.read(salesQuotesProvider.future);
      } catch (e) {
        debugPrint('Error fetching provider quotes fallback: $e');
      }
      final Map<String, dynamic> providerQuotesById = <String, dynamic>{};
      final Map<String, dynamic> providerQuotesByNumber = <String, dynamic>{};
      for (final quote in providerQuotes) {
        final id = quote.id?.toString().trim() ?? '';
        final number = quote.saleNumber?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          providerQuotesById[id] = quote;
        }
        if (number.isNotEmpty) {
          providerQuotesByNumber[number] = quote;
        }
      }

      // Fetch activities from Supabase
      List<dynamic> activitiesList = [];
      try {
        final activityResponse = await supabase
            .from('sales_quotation_activity')
            .select('*')
            .order('created_at', ascending: false);
        activitiesList = activityResponse as List<dynamic>;
      } catch (e) {
        debugPrint('Error fetching sales quotation activities: $e');
      }

      // Fetch users
      final Map<String, String> userNames = {};
      try {
        final usersResponse = await supabase
            .from('users')
            .select('id, full_name, email');
        for (final u in usersResponse as List<dynamic>) {
          final id = u['id']?.toString() ?? '';
          final fullName =
              u['full_name']?.toString() ??
              u['email']?.toString().split('@').first ??
              '';
          if (id.isNotEmpty && fullName.isNotEmpty) {
            userNames[id] = fullName;
          }
        }
      } catch (e) {
        debugPrint('Error fetching users for activities: $e');
      }

      // Fetch items from Supabase
      List<dynamic> allItems = [];
      if (quotes.isNotEmpty) {
        try {
          final itemsRes = await supabase
              .from('sales_quotation_items')
              .select('*')
              .inFilter('quotation_id', quotes.map((q) => q['id']).toList());
          allItems = itemsRes as List<dynamic>;
        } catch (e) {
          debugPrint('Error fetching quotation items: $e');
        }
      }

      // Fetch products used by these items
      final productIds = allItems
          .map((i) => i['product_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, String> productNames = {};
      final Map<String, String> productUnits = {};
      if (productIds.isNotEmpty) {
        try {
          final prodRes = await supabase
              .from('products')
              .select('id, product_name, unit_id')
              .inFilter('id', productIds);
          for (final p in (prodRes as List)) {
            productNames[p['id'].toString()] =
                p['product_name']?.toString() ?? '';
            productUnits[p['id'].toString()] =
                p['unit_id']?.toString() ?? 'pcs';
          }
        } catch (e) {
          debugPrint('Error fetching products: $e');
        }
      }

      final quoteIds = quotes
          .map((q) => q['id']?.toString().trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final Map<String, int> attachmentCountByQuoteId = <String, int>{};
      final Map<String, List<Map<String, dynamic>>> attachmentsByQuoteId =
          <String, List<Map<String, dynamic>>>{};
      if (quoteIds.isNotEmpty) {
        try {
          final attachmentsRes = await supabase
              .from('sales_quotation_attachments')
              .select('*')
              .inFilter('quotation_id', quoteIds);
          for (final row in (attachmentsRes as List<dynamic>)) {
            final attachment = Map<String, dynamic>.from(row as Map);
            final quoteId = attachment['quotation_id']?.toString().trim() ?? '';
            if (quoteId.isEmpty) continue;
            attachment['file_size'] ??= attachment['file_size_bytes'];
            attachmentCountByQuoteId[quoteId] =
                (attachmentCountByQuoteId[quoteId] ?? 0) + 1;
            attachmentsByQuoteId
                .putIfAbsent(quoteId, () => <Map<String, dynamic>>[])
                .add(attachment);
          }
        } catch (e) {
          debugPrint('Error fetching quotation attachments: $e');
        }
      }

      final loaded = quotes.map((q) {
        final dbId = q['id']?.toString() ?? '';
        final total = _quoteNum(q['grand_total']);
        final subTotal = _quoteNum(q['subtotal']);
        final halfTax = _quoteNum(q['tax_total']) / 2;
        final customerId = q['customer_id']?.toString().trim() ?? '';
        final rawCustomer =
            customersById[customerId] ??
            (q['customer'] is Map
                ? Map<String, dynamic>.from(q['customer'] as Map)
                : q['customer']);
        final customer = rawCustomer is Map<String, dynamic>
            ? _quoteMergeCustomerAddresses(
                rawCustomer,
                customerAddressesByCustomerId[customerId] ??
                    const <Map<String, dynamic>>[],
              )
            : rawCustomer;
        final quoteNumber = (q['quotation_number'] ?? q['id'] ?? '')
            .toString()
            .trim();
        final providerQuote =
            providerQuotesById[dbId] ?? providerQuotesByNumber[quoteNumber];
        final SalesCustomer? providerCustomer =
            providerQuote?.customer is SalesCustomer
            ? providerQuote.customer as SalesCustomer
            : null;
        final quotationDate = q['quotation_date']?.toString();
        final parsedDate = quotationDate != null
            ? DateTime.tryParse(quotationDate)
            : null;

        final List<_QuoteActivity> quoteActivities = [];
        final qActivities = activitiesList
            .where((act) => act['quotation_id'] == dbId)
            .toList();
        for (final act in qActivities) {
          final performedBy = act['performed_by']?.toString() ?? '';
          final performerName =
              userNames[performedBy] ??
              (performedBy == user?.id
                  ? (user?.fullName ??
                        user?.email.split('@').first ??
                        'zabnixprivatelimited')
                  : 'zabnixprivatelimited');

          final action = act['action']?.toString() ?? '';
          final description = act['description']?.toString() ?? '';
          final createdAtStr = act['created_at'] != null
              ? DateFormat(
                  'dd-MM-yyyy hh:mm a',
                ).format(DateTime.parse(act['created_at']).toLocal())
              : '';

          // Determine icon, tint and iconColor based on action type
          IconData icon = LucideIcons.pencil;
          Color tint = const Color(0xFFE0F2FE);
          Color iconColor = const Color(0xFF0284C7);

          if (action == 'created') {
            icon = LucideIcons.plusCircle;
            tint = const Color(0xFFDCFCE7);
            iconColor = const Color(0xFF10B981);
          } else if (action == 'emailed') {
            icon = LucideIcons.mail;
            tint = const Color(0xFFFEF3C7);
            iconColor = const Color(0xFFD97706);
          } else if (action == 'marked_as_sent' || action == 'sent') {
            icon = LucideIcons.mail;
            tint = const Color(0xFFDBEAFE);
            iconColor = const Color(0xFF2563EB);
          } else if (action == 'marked_as_accepted' || action == 'accepted') {
            icon = LucideIcons.pencil;
            tint = const Color(0xFFE0F2FE);
            iconColor = const Color(0xFF0284C7);
          } else if (action == 'marked_as_declined' || action == 'declined') {
            icon = LucideIcons.xCircle;
            tint = const Color(0xFFFEE2E2);
            iconColor = const Color(0xFFEF4444);
          }

          quoteActivities.add(
            _QuoteActivity(
              time: createdAtStr,
              message: '$description\nby $performerName',
              icon: icon,
              tint: tint,
              iconColor: iconColor,
            ),
          );
        }

        // Map quotation items for this specific quote
        final qItems = allItems
            .where((item) => item['quotation_id'] == dbId)
            .toList();
        final List<_QuoteItem> quoteItemsList = [];
        for (final item in qItems) {
          final pId = item['product_id']?.toString() ?? '';
          final pName = productNames[pId] ?? '-';
          final pUnit = productUnits[pId] ?? 'pcs';
          final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          final rateVal = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          final discVal =
              double.tryParse(item['discount_amount']?.toString() ?? '0') ?? 0;
          final amtVal = (qty * rateVal) - discVal;

          quoteItemsList.add(
            _QuoteItem(
              name: pName,
              description: item['description']?.toString() ?? '',
              quantity: qty.toStringAsFixed(0),
              unit: pUnit,
              price: _formatCurrency(rateVal),
              discount: discVal > 0 ? _formatCurrency(discVal) : '-',
              amount: _formatCurrency(amtVal),
              hsnSac: item['hsn_code']?.toString() ?? '-',
              productId: pId.isNotEmpty ? pId : null,
              taxId: item['tax_id']?.toString(),
              warehouseId: item['warehouse_id']?.toString(),
              discountType: item['discount_type']?.toString() ?? '%',
              rateValue: rateVal,
              quantityValue: qty,
              discountValue: discVal,
            ),
          );
        }

        // Fallback to default if no items
        if (quoteItemsList.isEmpty) {
          quoteItemsList.add(
            _QuoteItem(
              name:
                  (q['reference_number']?.toString().trim().isNotEmpty ?? false)
                  ? q['reference_number'].toString().trim()
                  : '-',
              description: q['customer_notes']?.toString().trim() ?? '',
              quantity: '1',
              unit: 'pcs',
              price: _formatCurrency(total),
              discount: '-',
              amount: _formatCurrency(total),
              hsnSac: '-',
            ),
          );
        }

        final resolvedSalesperson = (() {
          final salespersonMap = q['salesperson'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(q['salesperson'] as Map)
              : null;
          final salespersonName =
              salespersonMap?['full_name']?.toString().trim() ??
              salespersonMap?['email']?.toString().split('@').first.trim() ??
              '';
          if (salespersonName.isNotEmpty) return salespersonName;
          final providerSalesperson =
              providerQuote?.salesperson?.toString().trim() ?? '';
          if (providerSalesperson.isNotEmpty) return providerSalesperson;
          final salespersonId = q['salesperson_id']?.toString().trim() ?? '';
          if (salespersonId.isEmpty) return '-';
          return userNames[salespersonId] ?? salespersonId;
        })();
        final directBillingAddress = _quoteCustomerBillingAddress(customer);
        final directShippingAddress = _quoteCustomerShippingAddress(customer);
        final quoteBillingAddress = _quoteRecordBillingAddress(q);
        final quoteShippingAddress = _quoteRecordShippingAddress(q);
        final providerBillingAddress = _salesCustomerBillingAddress(
          providerCustomer,
        );
        final providerShippingAddress = _salesCustomerShippingAddress(
          providerCustomer,
        );

        return _QuoteOverviewRecord(
          dbId: dbId,
          id: quoteNumber,
          customerName: _quoteCustomerDisplayName(customer),
          date: parsedDate != null
              ? DateFormat('dd-MM-yyyy').format(parsedDate)
              : '-',
          status: (q['status'] ?? 'draft').toString().toUpperCase(),
          amount: _formatCurrency(total),
          location:
              (q['place_of_supply']?.toString().trim().isNotEmpty ?? false)
              ? q['place_of_supply'].toString().trim()
              : '-',
          placeOfSupply:
              (q['place_of_supply']?.toString().trim().isNotEmpty ?? false)
              ? q['place_of_supply'].toString().trim()
              : '-',
          salesperson: resolvedSalesperson,
          billingAddress: quoteBillingAddress != '-'
              ? quoteBillingAddress
              : (directBillingAddress != '-'
                    ? directBillingAddress
                    : providerBillingAddress),
          shippingAddress: quoteShippingAddress != '-'
              ? quoteShippingAddress
              : (directShippingAddress != '-'
                    ? directShippingAddress
                    : providerShippingAddress),
          customerEmail: _quoteCustomerEmail(customer),
          notes: (q['customer_notes']?.toString().trim().isNotEmpty ?? false)
              ? q['customer_notes'].toString().trim()
              : '-',
          terms:
              (q['terms_and_conditions']?.toString().trim().isNotEmpty ?? false)
              ? q['terms_and_conditions'].toString().trim()
              : '-',
          subTotal: _formatCurrency(subTotal),
          cgst: _formatCurrency(halfTax),
          sgst: _formatCurrency(halfTax),
          adjustment: _quoteNum(q['adjustment']).toStringAsFixed(2),
          roundOff: _formatCurrency(0),
          total: _formatCurrency(total),
          attachmentCount: attachmentCountByQuoteId[dbId] ?? 0,
          statusLabel: _statusLabel((q['status'] ?? 'draft').toString()),
          items: quoteItemsList,
          activities: quoteActivities,
          clonePayload: <String, dynamic>{
            'dbId': dbId,
            'quoteNumber': quoteNumber,
            'referenceNumber': q['reference_number']?.toString() ?? '',
            'subject': q['subject']?.toString() ?? '',
            'customerNotes': q['customer_notes']?.toString() ?? '',
            'termsAndConditions': q['terms_and_conditions']?.toString() ?? '',
            'shippingCharge': q['shipping_charge'],
            'adjustment': q['adjustment'],
            'quotationDate': q['quotation_date']?.toString(),
            'expiryDate': q['expiry_date']?.toString(),
            'customerId':
                customer['id']?.toString() ?? q['customer_id']?.toString(),
            'customer': Map<String, dynamic>.from(customer),
            'placeOfSupply': q['place_of_supply']?.toString(),
            'salespersonId': q['salesperson_id']?.toString(),
            'priceListId': q['price_list_id']?.toString(),
            'warehouseId': q['warehouse_id']?.toString(),
            'items': quoteItemsList
                .map(
                  (item) => <String, dynamic>{
                    'product_id': item.productId,
                    'name': item.name,
                    'description': item.description,
                    'quantity': item.quantityValue,
                    'unit': item.unit,
                    'rate': item.rateValue,
                    'discount_type': item.discountType,
                    'discount_value': item.discountValue,
                    'tax_id': item.taxId,
                    'warehouse_id': item.warehouseId,
                    'hsn_code': item.hsnSac,
                  },
                )
                .toList(),
          },
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _quotes
          ..clear()
          ..addAll(loaded);
        _quoteAttachmentsById
          ..clear()
          ..addAll(attachmentsByQuoteId);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quotes.clear();
        _quoteAttachmentsById.clear();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(value);
  }

  void _sortOverviewQuotes(String fieldId) {
    setState(() {
      if (_overviewSortByField == fieldId) {
        _overviewSortAscending = !_overviewSortAscending;
      } else {
        _overviewSortByField = fieldId;
        _overviewSortAscending = fieldId == 'date' || fieldId == 'created_time'
            ? false
            : true;
      }

      int compareText(String a, String b) =>
          a.toLowerCase().compareTo(b.toLowerCase());

      double amountValue(_QuoteOverviewRecord quote) =>
          _quoteNum(quote.total.replaceAll(RegExp(r'[^0-9.\-]'), ''));

      DateTime dateValue(_QuoteOverviewRecord quote) =>
          DateFormat('dd-MM-yyyy').parse(quote.date);

      _quotes.sort((a, b) {
        int result;
        switch (fieldId) {
          case 'payment_no':
            result = compareText(a.id, b.id);
            break;
          case 'vendor_name':
            result = compareText(a.customerName, b.customerName);
            break;
          case 'mode':
            result = compareText(a.salesperson, b.salesperson);
            break;
          case 'amount':
          case 'unused':
            result = amountValue(a).compareTo(amountValue(b));
            break;
          case 'created_time':
          case 'date':
          default:
            result = dateValue(a).compareTo(dateValue(b));
            break;
        }
        return _overviewSortAscending ? result : -result;
      });
    });
  }

  Widget _buildOverviewViewDropdownContent() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverviewViewOptionRow(
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

  Widget _buildOverviewSortMenuItem(String label, String fieldId) {
    final isActive = _overviewSortByField == fieldId;
    return MenuItemButton(
      onPressed: () => _sortOverviewQuotes(fieldId),
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isActive),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  static const List<String> _customizeOptions = [
    'Standard Template',
    'Change Template',
    'Edit Template',
    'Update Logo & Address',
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quotes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No saved quotes found.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.salesQuotations),
                child: const Text('Back to Quotes'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _selectedQuote;
    final orgSettings = ref.watch(orgSettingsProvider).valueOrNull;
    final logoUrl = orgSettings?.logoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.87)),
        key: _pageStackKey,
        child: Stack(
          children: [
            Row(
              children: [
                _buildLeftPanel(context, selected),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, selected),
                      _buildActionBar(selected),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 20, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (selected.status != 'DECLINED') ...[
                                _buildWhatsNextBar(selected),
                                const SizedBox(height: 18),
                              ],
                              _buildMainCard(selected, orgSettings, logoUrl),
                              const SizedBox(height: 18),
                              _buildTermsCard(selected),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showAttachmentOverlay) _buildAttachmentOverlay(selected),
            if (_showQuotePreferencesPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeQuotePreferencesPanel,
                  child: Container(color: Colors.black.withValues(alpha: 0.04)),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: _buildQuotePreferencesPanel(),
              ),
            ],
            if (_showCommentsPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeCommentsPanel,
                  child: Container(color: Colors.black.withValues(alpha: 0.03)),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: _buildCommentsPanel(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _convertQuoteToSalesOrder(_QuoteOverviewRecord quote) async {
    try {
      final supabase = Supabase.instance.client;
      final resolvedDbId = await _resolveExistingQuotationDbId(quote);
      if (resolvedDbId == null || resolvedDbId.isEmpty) {
        throw Exception('Quote record not found for ${quote.id}.');
      }

      final quoteRow = await supabase
          .from('sales_quotations')
          .select(
            'id, customer_id, quotation_date, reference_number, '
            'customer_notes, terms_and_conditions, subtotal, tax_total, '
            'shipping_charge, adjustment, grand_total, place_of_supply, '
            'price_list_id, salesperson_id, customer:customers(*)',
          )
          .eq('id', resolvedDbId)
          .maybeSingle();
      if (quoteRow == null) {
        throw Exception('Quote data could not be loaded for ${quote.id}.');
      }

      final itemRows = await supabase
          .from('sales_quotation_items')
          .select(
            'product_id, quantity, rate, description, discount_type, '
            'discount_value, tax_id, hsn_code, warehouse_id',
          )
          .eq('quotation_id', resolvedDbId)
          .order('line_no', ascending: true);

      final productIds = (itemRows as List<dynamic>)
          .map((row) => row['product_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final Map<String, Item> productsById = <String, Item>{};
      if (productIds.isNotEmpty) {
        final products = await supabase
            .from('products')
            .select('*')
            .inFilter('id', productIds);
        for (final row in products as List<dynamic>) {
          final map = Map<String, dynamic>.from(row as Map);
          final item = Item.fromJson(map);
          if ((item.id ?? '').trim().isNotEmpty) {
            productsById[item.id!.trim()] = item;
          }
        }
      }

      final salesOrderItems = (itemRows as List<dynamic>).map((row) {
        final itemMap = Map<String, dynamic>.from(row as Map);
        final productId = itemMap['product_id']?.toString() ?? '';
        final product = productsById[productId];
        return SalesOrderItem(
          itemId: productId,
          quantity: _quoteNum(itemMap['quantity']),
          rate: _quoteNum(itemMap['rate']),
          description: itemMap['description']?.toString(),
          discount: _quoteNum(itemMap['discount_value']),
          discountType:
              itemMap['discount_type']?.toString().toLowerCase() == 'value'
              ? 'value'
              : '%',
          taxId: itemMap['tax_id']?.toString(),
          hsnCode: itemMap['hsn_code']?.toString().trim().isNotEmpty == true
              ? itemMap['hsn_code']?.toString()
              : product?.hsnCode,
          warehouseId: itemMap['warehouse_id']?.toString(),
          item: product,
          accountId: product?.salesAccountId,
          priceListId: quoteRow['price_list_id']?.toString(),
        );
      }).toList();

      final customerMap = quoteRow['customer'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(quoteRow['customer'] as Map)
          : null;

      final salesOrderDraft = SalesOrder(
        id: '',
        customerId: quoteRow['customer_id']?.toString() ?? '',
        saleNumber: '',
        reference: quoteRow['reference_number']?.toString(),
        saleDate:
            DateTime.tryParse(quoteRow['quotation_date']?.toString() ?? '') ??
            DateTime.now(),
        status: 'draft',
        documentType: 'order',
        items: salesOrderItems,
        subTotal: _quoteNum(quoteRow['subtotal']),
        taxTotal: _quoteNum(quoteRow['tax_total']),
        discountTotal: 0,
        shippingCharges: _quoteNum(quoteRow['shipping_charge']),
        adjustment: _quoteNum(quoteRow['adjustment']),
        total: _quoteNum(quoteRow['grand_total']),
        customerNotes: quoteRow['customer_notes']?.toString(),
        termsAndConditions: quoteRow['terms_and_conditions']?.toString(),
        placeOfSupply: quoteRow['place_of_supply']?.toString(),
        priceListId: quoteRow['price_list_id']?.toString(),
        salesperson: quoteRow['salesperson_id']?.toString(),
        customer: customerMap != null
            ? SalesCustomer.fromJson(customerMap)
            : null,
        gstTreatment: customerMap?['gst_treatment']?.toString(),
      );

      if (!mounted) return;
      context.goNamed(AppRoutes.salesOrdersCreate, extra: salesOrderDraft);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to convert quote to sales order: $e');
    }
  }

  Widget _buildLeftPanel(BuildContext context, _QuoteOverviewRecord selected) {
    return Container(
      width: 328,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Container(
            height: 92,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                MenuAnchor(
                  controller: _viewMenuController,
                  style: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: const WidgetStatePropertyAll(
                      Colors.white,
                    ),
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
                      onTap: () =>
                          isOpen ? controller.close() : controller.open(),
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
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isOpen
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 14,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  menuChildren: [_buildOverviewViewDropdownContent()],
                ),
                const Spacer(),
                _topSquareButton(
                  icon: LucideIcons.plus,
                  background: const Color(0xFF22C55E),
                  iconColor: Colors.white,
                  onTap: () => context.go(AppRoutes.salesQuotationsCreate),
                ),
                const SizedBox(width: 8),
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
                    return _topSquareButton(
                      icon: LucideIcons.moreHorizontal,
                      background: const Color(0xFFF8FAFC),
                      iconColor: const Color(0xFF111827),
                      onTap: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
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
                        _buildOverviewSortMenuItem('Date', 'date'),
                        _buildOverviewSortMenuItem('Quote #', 'payment_no'),
                        _buildOverviewSortMenuItem(
                          'Customer Name',
                          'vendor_name',
                        ),
                        _buildOverviewSortMenuItem('Salesperson', 'mode'),
                        _buildOverviewSortMenuItem('Amount', 'amount'),
                        _buildOverviewSortMenuItem(
                          'Created Time',
                          'created_time',
                        ),
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
                              const SnackBar(
                                content: Text('Importing quotes...'),
                              ),
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
                                content: Text('Importing quote data...'),
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
                              const SnackBar(
                                content: Text('Exporting quotes...'),
                              ),
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
                      onPressed: () async {
                        await _loadQuotes();
                        if (!context.mounted) return;
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
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _quotes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (context, index) {
                final quote = _quotes[index];
                final isSelected = quote.id == selected.id;
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setStateBuilder) {
                    return InkWell(
                      onTap: () {
                        _closeAttachmentOverlay();
                        final navId = quote.dbId ?? quote.id;
                        context.go(
                          AppRoutes.salesQuotationsDetail.replaceAll(
                            ':id',
                            navId,
                          ),
                        );
                      },
                      onHover: (hovering) {
                        setStateBuilder(() {
                          isHovered = hovering;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
                        color: isSelected
                            ? const Color(0xFFF5F7FF)
                            : (isHovered
                                  ? const Color(0xFFF3F4F6)
                                  : Colors.white),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  value: false,
                                  onChanged: (_) {},
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          quote.customerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        quote.amount,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        quote.id,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        quote.date,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        quote.status,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: quote.status == 'ACCEPTED'
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF2563EB),
                                        ),
                                      ),
                                      if (quote.status == 'SENT') ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          LucideIcons.mail,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ],
                                      const Spacer(),
                                      if (quote.attachmentCount > 0)
                                        const Icon(
                                          LucideIcons.paperclip,
                                          size: 16,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _QuoteOverviewRecord selected) {
    // final selectedAttachmentRows =
    //     _quoteAttachmentsById[(selected.dbId ?? '').trim()] ??
    //     const <Map<String, dynamic>>[];
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location: ${selected.location}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selected.id,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            key: _attachmentButtonKey,
            child: _topSquareButton(
              icon: LucideIcons.paperclip,
              background: Colors.white,
              iconColor: const Color(0xFF64748B),
              borderColor: const Color(0xFFDDE3EE),
              badgeCount: selected.attachmentCount,
              onTap: () => _toggleAttachmentOverlay(selected),
            ),
          ),
          const SizedBox(width: 10),
          _topSquareButton(
            icon: LucideIcons.messageSquare,
            background: Colors.white,
            iconColor: const Color(0xFF64748B),
            borderColor: const Color(0xFFDDE3EE),
            onTap: () {
              _showCommentsPanel ? _closeCommentsPanel() : _openCommentsPanel();
            },
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _closeOverviewToReportPage,
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(LucideIcons.x, size: 24, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(_QuoteOverviewRecord selected) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _actionTextButton(LucideIcons.pencil, 'Edit', () {
              final dbId = selected.dbId;
              if (dbId != null && dbId.isNotEmpty) {
                context.go('/sales/quotations/$dbId/edit');
              } else {
                ZerpaiToast.error(
                  context,
                  'Cannot edit: quote ID not available.',
                );
              }
            }),
            _divider(),
            _menuButton(LucideIcons.mail, 'Send', const [
              'Send Email',
              'Send SMS',
            ]),
            _divider(),
            _actionTextButton(
              LucideIcons.share2,
              'Share',
              () => _showShareQuoteLinkDialog(context),
            ),
            _divider(),
            _menuButton(LucideIcons.fileText, 'PDF/Print', const [
              'PDF',
              'Print',
            ]),
            _divider(),
            _menuButton(LucideIcons.repeat, 'Convert', const [
              'Convert to Invoice',
              'Convert to Sales Order',
            ]),
            _divider(),
            _menuIconOnly([
              if (selected.status != 'ACCEPTED') 'Mark as Accepted',
              if (selected.status == 'ACCEPTED') 'Mark as Declined',
              'Clone',
              'Delete',
              'Quote Preferences',
            ]),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsSent(_QuoteOverviewRecord q) async {
    setState(() {
      final index = _quotes.indexWhere((quote) => quote.id == q.id);
      if (index != -1) {
        final old = _quotes[index];
        _quotes[index] = _QuoteOverviewRecord(
          dbId: old.dbId,
          id: old.id,
          customerName: old.customerName,
          date: old.date,
          status: 'SENT',
          amount: old.amount,
          location: old.location,
          placeOfSupply: old.placeOfSupply,
          salesperson: old.salesperson,
          billingAddress: old.billingAddress,
          shippingAddress: old.shippingAddress,
          customerEmail: old.customerEmail,
          notes: old.notes,
          terms: old.terms,
          subTotal: old.subTotal,
          cgst: old.cgst,
          sgst: old.sgst,
          adjustment: old.adjustment,
          roundOff: old.roundOff,
          total: old.total,
          attachmentCount: old.attachmentCount,
          statusLabel: 'SENT',
          items: old.items,
          activities: old.activities,
          clonePayload: old.clonePayload,
        );
      }
    });

    try {
      await _updateQuoteStatusWithActivity(
        quote: q,
        status: 'sent',
        action: 'marked_as_sent',
        description: 'Quote marked as sent',
      );

      ref.invalidate(salesQuotesProvider);
      _notifyQuoteReportRefresh();

      if (mounted) {
        ZerpaiToast.success(context, 'Quote marked as sent successfully.');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to update quote status in DB: $e');
      }
    }
  }

  Widget _buildWhatsNextBar(_QuoteOverviewRecord selected) {
    final isDraft = selected.status.toLowerCase() == 'draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 12),
          const Text(
            "WHAT'S NEXT?",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDraft
                  ? 'Go ahead and email this quote to your customer or simply mark it as sent.'
                  : 'Convert this quote to an invoice or a sales order.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 16),
          if (isDraft) ...[
            InkWell(
              onTap: () => context.go('/sales/quotations/${selected.id}/email'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22A95E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Send Quote',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _markAsSent(selected),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Mark As Sent',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            _greenMenuButton('Convert', const [
              'Convert to Invoice',
              'Convert to Sales Order',
            ]),
            const SizedBox(width: 10),
            _whiteMenuButton('Create', const ['Create Retainer Invoice']),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMainCard(
    _QuoteOverviewRecord selected,
    dynamic orgSettings,
    String? logoUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tabButton('Quote Details', 0),
                          const SizedBox(width: 28),
                          _tabButton('Activity', 1),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _toggleChip('Details', 0),
                            _toggleChip('PDF', 1),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    _tabButton('Quote Details', 0),
                    const SizedBox(width: 28),
                    _tabButton('Activity', 1),
                    const Spacer(),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          _toggleChip('Details', 0),
                          _toggleChip('PDF', 1),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: _mainTabIndex == 0
                ? (_viewTabIndex == 0
                      ? _buildDetailView(selected)
                      : _buildPdfView(selected, orgSettings, logoUrl))
                : _buildActivityView(selected),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(_QuoteOverviewRecord selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  selected.id,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selected.statusLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total : ${selected.total}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 36),
            if (compact)
              Column(
                children: [
                  _infoRow('Quote Number', selected.id),
                  _infoRow('Creation Date', selected.date),
                  _infoRow('Place of Supply', selected.placeOfSupply),
                  _infoRow('Quote Date', selected.date),
                  _infoRowWithBadge('Salesperson', selected.salesperson),
                  _infoRowWithGear('PDF Template', 'Spreadsheet Template'),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _infoRow('Quote Number', selected.id),
                        _infoRow('Creation Date', selected.date),
                        _infoRow('Place of Supply', selected.placeOfSupply),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        _infoRow('Quote Date', selected.date),
                        _infoRowWithBadge('Salesperson', selected.salesperson),
                        _infoRowWithGear(
                          'PDF Template',
                          'Spreadsheet Template',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            const Text(
              'Customer Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            if (compact)
              Column(
                children: [
                  _infoRowWithCustomerDot('Name', selected.customerName),
                  _infoAddressRow('Billing Address', selected.billingAddress),
                  _infoAddressRow('Shipping Address', selected.shippingAddress),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _infoRowWithCustomerDot('Name', selected.customerName),
                        _infoAddressRow(
                          'Billing Address',
                          selected.billingAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 44),
                        _infoAddressRow(
                          'Shipping Address',
                          selected.shippingAddress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 36),
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    selected.items.length.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildItemsTable(selected),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? constraints.maxWidth : 430,
                ),
                child: Column(
                  children: [
                    _summaryRow('Sub Total', selected.subTotal, bold: true),
                    _summaryRow('CGST2.5', selected.cgst),
                    _summaryRow('SGST2.5', selected.sgst),
                    _summaryRow('Adjustment', selected.adjustment),
                    _summaryRow('Round Off', selected.roundOff),
                    const Divider(color: Color(0xFFE5E7EB)),
                    _summaryRow(
                      'Total',
                      selected.total,
                      bold: true,
                      large: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 54),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 26),
            const Text(
              'Email Recipients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Z',
                      style: TextStyle(fontSize: 10, color: Color(0xFFF97316)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      selected.customerEmail,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 42),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selected.notes,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityView(_QuoteOverviewRecord selected) {
    return SizedBox(
      height: 456,
      child: Column(
        children: [
          for (int index = 0; index < selected.activities.length; index++) ...[
            _activityRow(selected.activities[index]),
            if (index != selected.activities.length - 1)
              const Divider(height: 28, color: Color(0xFFE5E7EB)),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfView(
    _QuoteOverviewRecord selected,
    dynamic orgSettings,
    String? logoUrl,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
      color: Colors.white,
      child: Align(
        alignment: Alignment.topCenter,
        child: MouseRegion(
          onEnter: (_) => setState(() => _pdfHovered = true),
          onExit: (_) => setState(() => _pdfHovered = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 1008,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: PaymentCornerRibbon(
                        label: selected.statusLabel,
                        color: selected.status == 'ACCEPTED'
                            ? const Color(0xFF20B15A)
                            : selected.status == 'DECLINED'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: AnimatedOpacity(
                        opacity:
                            (_pdfHovered || _customizeMenuController.isOpen)
                            ? 1.0
                            : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring:
                              !(_pdfHovered || _customizeMenuController.isOpen),
                          child: MenuAnchor(
                            controller: _customizeMenuController,
                            onClose: () => setState(() {}),
                            style: const MenuStyle(
                              alignment: AlignmentDirectional.bottomEnd,
                              minimumSize: WidgetStatePropertyAll(Size(200, 0)),
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              surfaceTintColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              elevation: WidgetStatePropertyAll(8),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  side: BorderSide(color: AppTheme.borderColor),
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
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen,
                                    borderRadius: BorderRadius.circular(4),
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
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        controller.isOpen
                                            ? LucideIcons.chevronUp
                                            : LucideIcons.chevronDown,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            menuChildren: _customizeOptions
                                .map(
                                  (item) =>
                                      _buildDropdownMenuItem(context, item, () {
                                        _customizeMenuController.close();
                                        _handleMenuAction(item);
                                      }, showIcon: false),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(48, 92, 36, 26),
                      child: _buildPdfSheet(selected, orgSettings, logoUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 1008,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'PDF Template : ',
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
    );
  }

  Widget _buildPdfSheet(
    _QuoteOverviewRecord selected,
    dynamic orgSettings,
    String? logoUrl,
  ) {
    final companyName = orgSettings?.name?.toString().trim().isNotEmpty == true
        ? orgSettings.name.toString().trim().toUpperCase()
        : '-';
    final orgLines = _orgProfileLines(orgSettings);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _pdfRuleColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 138,
            child: Row(
              children: [
                SizedBox(
                  width: 176,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 34),
                    child: _buildPdfLogoBox(logoUrl),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 26,
                          left: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < orgLines.length; i++) ...[
                                Text(
                                  orgLines[i],
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (i != orgLines.length - 1)
                                  const SizedBox(height: 2),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 12,
                          child: const Text(
                            'QUOTE',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
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
          Container(
            height: 54,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _pdfRuleColor, width: 0.8),
                bottom: BorderSide(color: _pdfRuleColor, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _pdfRuleColor, width: 0.8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('#', style: TextStyle(fontSize: 11)),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ': ${selected.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ': ${selected.date}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Place Of Supply',
                          style: TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          ': ${selected.placeOfSupply} (32)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 72,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _pdfRuleColor, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(6, 2, 6, 0),
                  child: Text(
                    'Bill To',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                  child: Text(
                    selected.customerName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(6, 2, 6, 0),
                  child: Text(
                    'GSTIN 32ABACS3075R1ZX',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Table(
            border: TableBorder.all(color: _pdfRuleColor, width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(32),
              1: FlexColumnWidth(3.5),
              2: FlexColumnWidth(1.1),
              3: FlexColumnWidth(1.0),
              4: FlexColumnWidth(1.0),
              5: FlexColumnWidth(0.7),
              6: FlexColumnWidth(0.7),
              7: FlexColumnWidth(0.7),
              8: FlexColumnWidth(0.7),
              9: FlexColumnWidth(1.4),
            },
            children: [
              const TableRow(
                children: [
                  _PdfCell('#', bold: true, center: true),
                  _PdfCell('Item & Description', bold: true),
                  _PdfCell('HSN/SAC', bold: true, center: true),
                  _PdfCell('Qty', bold: true, center: true),
                  _PdfCell('Rate', bold: true, right: true),
                  _PdfCell('CGST', bold: true, center: true),
                  _PdfCell('', bold: true, center: true),
                  _PdfCell('SGST', bold: true, center: true),
                  _PdfCell('', bold: true, center: true),
                  _PdfCell('Amount', bold: true, right: true),
                ],
              ),
              const TableRow(
                children: [
                  _PdfCell('', bold: true, center: true),
                  _PdfCell('', bold: true),
                  _PdfCell('', bold: true, center: true),
                  _PdfCell('', bold: true, center: true),
                  _PdfCell('', bold: true, right: true),
                  _PdfCell('%', bold: true, center: true),
                  _PdfCell('Amt', bold: true, center: true),
                  _PdfCell('%', bold: true, center: true),
                  _PdfCell('Amt', bold: true, center: true),
                  _PdfCell('', bold: true, right: true),
                ],
              ),
              ...selected.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return TableRow(
                  children: [
                    _PdfCell((idx + 1).toString(), center: true),
                    _PdfItemCell(title: item.name, subtitle: item.description),
                    _PdfCell(item.hsnSac, center: true),
                    _PdfCell('${item.quantity}.00\n${item.unit}', center: true),
                    _PdfCell(
                      item.price.replaceAll('₹', '').trim(),
                      right: true,
                    ),
                    const _PdfCell('2.5%', center: true),
                    const _PdfCell('49.75', center: true),
                    const _PdfCell('2.5%', center: true),
                    const _PdfCell('49.75', center: true),
                    _PdfCell(
                      item.amount.replaceAll('₹', '').trim(),
                      right: true,
                    ),
                  ],
                );
              }),
            ],
          ),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _pdfRuleColor, width: 0.8),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total In Words',
                          style: TextStyle(fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _amountToWords(_parseCurrencyValue(selected.total)),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text('Notes', style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          selected.notes.trim().isNotEmpty
                              ? selected.notes.trim()
                              : '-',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                          child: Column(
                            children: const [
                              _PdfSummaryRow('Sub Total', '1,990.00'),
                              _PdfSummaryRow('CGST2.5 (2.5%)', '49.75'),
                              _PdfSummaryRow('SGST2.5 (2.5%)', '49.75'),
                              _PdfSummaryRow('Rounding', '0.50'),
                              SizedBox(height: 4),
                              _PdfSummaryRow('Total', '₹2,090.00', bold: true),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 38,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _pdfRuleColor, width: 0.8),
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 2),
                        child: const Text(
                          'Authorized Signature',
                          style: TextStyle(fontSize: 11),
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
    );
  }

  Widget _buildPdfLogoBox(String? logoUrl) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _pdfRuleColor, width: 0.8),
        ),
        padding: const EdgeInsets.all(2),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPdfLogoFallback(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildPdfLogoFallback();
          },
        ),
      );
    }

    return _buildPdfLogoFallback();
  }

  Widget _buildPdfLogoFallback() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: _pdfRuleColor, width: 0.8),
      ),
      child: const Center(
        child: Text(
          'IMAGE',
          style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildTermsCard(_QuoteOverviewRecord selected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms and Conditions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 50),
          Center(
            child: Text(
              selected.terms,
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _buildItemsTable(_QuoteOverviewRecord selected) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB)),
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  'S.NO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'ITEM',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: Text(
                  'PRICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: Text(
                  'DISCOUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: Text(
                  'AMOUNT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...selected.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    (idx + 1).toString(),
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      Text(
                        item.quantity,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.unit,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Text(
                    item.price,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Text(
                    item.discount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    item.amount,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _activityRow(_QuoteActivity activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 270,
          child: Text(
            activity.time,
            style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: activity.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.icon, size: 14, color: activity.iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  activity.message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _mainTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _mainTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _toggleChip(String label, int index) {
    final isActive = _viewTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _viewTabIndex = index),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isActive ? Border.all(color: const Color(0xFFDCE3EE)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFF111827) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoAddressRow(String label, String value) {
    final lines = _quoteAddressLines(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == lines.length - 1 ? 0 : 4,
                    ),
                    child: Text(
                      lines[i],
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: i == 0 && lines[i] != '-'
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithBadge(String label, String value) {
    final trimmedValue = value.trim();
    final badgeText = trimmedValue.isNotEmpty && trimmedValue != '-'
        ? trimmedValue.characters.first.toUpperCase()
        : '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFB7185),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithCustomerDot(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'C',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFB7185)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithGear(String label, String value) {
    const settingsItems = <String>[
      'Spreadsheet\nTemplate',
      'Change Template',
      'Edit Template',
      'Update Logo & Address',
      'Manage Custom Fields',
      'Terms & Conditions',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 2),
                  MenuAnchor(
                    style: const MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.white),
                      surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 6),
                      ),
                      elevation: WidgetStatePropertyAll(10),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    menuChildren: settingsItems
                        .map(
                          (item) => _buildSettingsMenuItem(
                            context,
                            item,
                            enabled: item != 'Spreadsheet\nTemplate',
                            onTap: () =>
                                _handleMenuAction(item.replaceAll('\n', ' ')),
                          ),
                        )
                        .toList(),
                    builder: (context, controller, child) {
                      return InkWell(
                        onTap: () => controller.isOpen
                            ? controller.close()
                            : controller.open(),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            LucideIcons.settings,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    bool large = false,
  }) {
    final fontSize = large ? 18.0 : 15.0;
    final weight = bold ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: weight,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: weight,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTextButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String item) async {
    switch (item) {
      case 'Send Email':
        context.push(
          AppRoutes.salesQuotationsEmail.replaceAll(':id', _selectedQuote.id),
        );
        break;
      case 'Send SMS':
        ZerpaiToast.success(context, 'SMS sent successfully');
        break;
      case 'PDF':
      case 'Download PDF':
        try {
          final orgSettings = ref.read(orgSettingsProvider).asData?.value;
          final bytes = await _buildPrintableQuotationPdf(
            _selectedQuote,
            orgSettings,
          );
          await Printing.sharePdf(
            bytes: bytes,
            filename: '${_selectedQuote.id}.pdf',
          );
        } catch (e) {
          ZerpaiToast.error(context, 'Failed to generate PDF: $e');
        }
        break;
      case 'Print':
        try {
          final orgSettings = ref.read(orgSettingsProvider).asData?.value;
          final bytes = await _buildPrintableQuotationPdf(
            _selectedQuote,
            orgSettings,
          );
          await Printing.layoutPdf(
            onLayout: (_) async => bytes,
            name: _selectedQuote.id,
          );
        } catch (e) {
          ZerpaiToast.error(context, 'Failed to print document: $e');
        }
        break;
      case 'Standard Template':
        setState(() => _selectedTemplate = 'Standard Template');
        break;
      case 'Change Template':
        ZerpaiToast.info(context, 'Template chooser is not configured yet');
        break;
      case 'Edit Template':
        ZerpaiToast.info(context, 'Template editor is not configured yet');
        break;
      case 'Update Logo & Address':
        ZerpaiToast.info(
          context,
          'Logo and address editor is not configured yet',
        );
        break;
      case 'Convert to Invoice':
        ZerpaiToast.success(context, 'Converted to Invoice successfully');
        break;
      case 'Convert to Sales Order':
        await _convertQuoteToSalesOrder(_selectedQuote);
        break;
      case 'Create Project':
        ZerpaiToast.success(context, 'Project created successfully');
        break;
      case 'Mark as Accepted':
        setState(() {
          final index = _quotes.indexWhere((q) => q.id == _selectedQuote.id);
          if (index != -1) {
            final old = _quotes[index];
            _quotes[index] = _QuoteOverviewRecord(
              dbId: old.dbId,
              id: old.id,
              customerName: old.customerName,
              date: old.date,
              status: 'ACCEPTED',
              amount: old.amount,
              location: old.location,
              placeOfSupply: old.placeOfSupply,
              salesperson: old.salesperson,
              billingAddress: old.billingAddress,
              shippingAddress: old.shippingAddress,
              customerEmail: old.customerEmail,
              notes: old.notes,
              terms: old.terms,
              subTotal: old.subTotal,
              cgst: old.cgst,
              sgst: old.sgst,
              adjustment: old.adjustment,
              roundOff: old.roundOff,
              total: old.total,
              attachmentCount: old.attachmentCount,
              statusLabel: 'Accepted',
              items: old.items,
              activities: [
                _QuoteActivity(
                  time: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                  message: 'Quote marked as accepted\nby zabnixprivatelimited',
                  icon: LucideIcons.pencil,
                  tint: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                ),
                ...old.activities,
              ],
              clonePayload: old.clonePayload,
            );
          }
        });
        // Save to Supabase
        Future.microtask(() async {
          try {
            await _updateQuoteStatusWithActivity(
              quote: _selectedQuote,
              status: 'accepted',
              action: 'marked_as_accepted',
              description: 'Quote marked as accepted',
            );
            ref.invalidate(salesQuotesProvider);
            _notifyQuoteReportRefresh();
          } catch (e) {
            debugPrint('Failed to save accepted activity to DB: $e');
          }
        });
        ZerpaiToast.success(context, 'Quote marked as accepted');
        break;
      case 'Mark as Declined':
        setState(() {
          final index = _quotes.indexWhere((q) => q.id == _selectedQuote.id);
          if (index != -1) {
            final old = _quotes[index];
            _quotes[index] = _QuoteOverviewRecord(
              dbId: old.dbId,
              id: old.id,
              customerName: old.customerName,
              date: old.date,
              status: 'DECLINED',
              amount: old.amount,
              location: old.location,
              placeOfSupply: old.placeOfSupply,
              salesperson: old.salesperson,
              billingAddress: old.billingAddress,
              shippingAddress: old.shippingAddress,
              customerEmail: old.customerEmail,
              notes: old.notes,
              terms: old.terms,
              subTotal: old.subTotal,
              cgst: old.cgst,
              sgst: old.sgst,
              adjustment: old.adjustment,
              roundOff: old.roundOff,
              total: old.total,
              attachmentCount: old.attachmentCount,
              statusLabel: 'Declined',
              items: old.items,
              activities: [
                _QuoteActivity(
                  time: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                  message: 'Quote marked as declined\nby zabnixprivatelimited',
                  icon: LucideIcons.xCircle,
                  tint: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFEF4444),
                ),
                ...old.activities,
              ],
              clonePayload: old.clonePayload,
            );
          }
        });
        // Save to Supabase
        Future.microtask(() async {
          try {
            await _updateQuoteStatusWithActivity(
              quote: _selectedQuote,
              status: 'declined',
              action: 'marked_as_declined',
              description: 'Quote marked as declined',
            );
            ref.invalidate(salesQuotesProvider);
            _notifyQuoteReportRefresh();
          } catch (e) {
            debugPrint('Failed to save declined activity to DB: $e');
          }
        });
        ZerpaiToast.success(context, 'Quote marked as declined');
        break;
      case 'Clone':
        final currentPathParameters = GoRouterState.of(context).pathParameters;
        context.goNamed(
          AppRoutes.salesQuotationsCreate,
          pathParameters: {
            if (currentPathParameters['orgSystemId'] != null)
              'orgSystemId': currentPathParameters['orgSystemId']!,
          },
          queryParameters: {
            'cloneId': (_selectedQuote.dbId ?? _selectedQuote.id).trim(),
          },
          extra: _selectedQuote.clonePayload,
        );
        break;
      case 'Delete':
        final confirmed = await showZerpaiConfirmationDialog(
          context,
          title: 'Delete Quote',
          message:
              'Are you sure you want to delete this quote? This action cannot be undone.',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
          variant: ZerpaiConfirmationVariant.danger,
        );
        if (confirmed) {
          try {
            final quoteToDelete = _selectedQuote;
            await _deleteQuoteFromDb(quoteToDelete);
            ref.invalidate(salesQuotesProvider);
            _notifyQuoteReportRefresh();
            final idToDelete = quoteToDelete.id;
            setState(() {
              _quotes.removeWhere((q) => q.id == idToDelete);
            });
            if (!mounted) return;
            if (_quotes.isNotEmpty) {
              final nextQuote = _quotes.first;
              final nextId = nextQuote.dbId ?? nextQuote.id;
              final currentPathParameters = GoRouterState.of(
                context,
              ).pathParameters;
              context.goNamed(
                AppRoutes.salesQuotationsDetail,
                pathParameters: {...currentPathParameters, 'id': nextId},
              );
            } else {
              context.go(AppRoutes.salesQuotations);
            }
            ZerpaiToast.success(context, 'Quote deleted successfully');
          } catch (e) {
            if (!mounted) return;
            ZerpaiToast.error(context, 'Failed to delete quote: $e');
          }
        }
        break;
      case 'Quote Preferences':
        _openQuotePreferencesPanel();
        break;
      case 'Create Retainer Invoice':
        ZerpaiToast.success(context, 'Retainer Invoice created successfully');
        break;
      case 'Invoice':
        ZerpaiToast.success(context, 'Invoice created successfully');
        break;
      case 'Sales Order':
        ZerpaiToast.success(context, 'Sales Order created successfully');
        break;
    }
  }

  // ignore: unused_element
  Future<Uint8List> _generateQuotationPdf(
    _QuoteOverviewRecord quote,
    dynamic org,
  ) async {
    pw.ThemeData? theme;
    // Load custom Inter font to support Indian Rupee symbol (₹) and other special characters
    try {
      final fontData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final fontRegular = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      final fontBold = pw.Font.ttf(boldFontData);

      theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    } catch (e) {
      debugPrint('Failed to load custom Inter fonts for PDF: $e');
    }

    final doc = pw.Document(theme: theme);

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
                        width: 130,
                        height: 56,
                        color: const PdfColor.fromInt(0xFF101820),
                        child: pw.Center(
                          child: pw.Text(
                            'LOGO',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        (org?.name ?? 'YOUR COMPANY')
                            .toString()
                            .trim()
                            .toUpperCase(),
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
                        'QUOTATION',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Quote# ' + quote.id,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
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
                        'Date: ' + quote.date,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Status: ' + quote.statusLabel,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Salesperson: ' + quote.salesperson,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Customer: ' + quote.customerName,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Email: ' + quote.customerEmail,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Location: ' + quote.location,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.8,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Item & Description',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Rate',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...quote.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                              if (item.description.isNotEmpty)
                                pw.Text(
                                  item.description,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.quantity + ' ' + item.unit,
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.price.replaceAll('₹', 'Rs. '),
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.amount.replaceAll('₹', 'Rs. '),
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _pwTotalRow(
                        'Sub Total',
                        quote.subTotal.replaceAll('₹', 'Rs. '),
                      ),
                      _pwTotalRow('CGST', quote.cgst.replaceAll('₹', 'Rs. ')),
                      _pwTotalRow('SGST', quote.sgst.replaceAll('₹', 'Rs. ')),
                      _pwTotalRow(
                        'Round Off',
                        quote.roundOff.replaceAll('₹', 'Rs. '),
                      ),
                      pw.Divider(color: PdfColors.grey400, thickness: 1),
                      _pwTotalRow(
                        'Total',
                        quote.total.replaceAll('₹', 'Rs. '),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                quote.notes,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pwTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenuItem(
    BuildContext context,
    String item, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    bool isHovered = false;
    return MenuItemButton(
      onPressed: enabled ? onTap : null,
      style:
          MenuItemButton.styleFrom(
            padding: EdgeInsets.zero,
            disabledForegroundColor: const Color(0xFF98A2B3),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
      child: StatefulBuilder(
        builder: (context, setOverlayState) {
          return MouseRegion(
            onEnter: (_) => setOverlayState(() => isHovered = true),
            onExit: (_) => setOverlayState(() => isHovered = false),
            child: Container(
              width: 182,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: enabled && isHovered
                    ? const Color(0xFF4A8DF6)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: !enabled
                      ? const Color(0xFF98A2B3)
                      : isHovered
                      ? Colors.white
                      : const Color(0xFF4B5563),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuotePreferencesPanel() {
    return Container(
      width: 760,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                _buildQuotePreferencesTab('Preferences', 0),
                const SizedBox(width: 30),
                _buildQuotePreferencesTab('Fields', 1),
                const Spacer(),
                InkWell(
                  onTap: () => ZerpaiToast.info(
                    context,
                    'All preferences page is not configured yet',
                  ),
                  child: const Text(
                    'All Preferences',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: _closeQuotePreferencesPanel,
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: _quotePreferencesTabIndex == 0
                  ? _buildQuotePreferencesTabBody()
                  : _buildQuoteFieldsTabBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsPanel() {
    final selected = _selectedQuote;
    final comments = _commentsFor(selected);
    final canAddComment = _commentDraftCtrl.text.trim().isNotEmpty;
    return Container(
      width: 410,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _closeCommentsPanel,
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD7DEEA)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6F8FB),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'B',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(width: 22),
                              Text(
                                'I',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(width: 24),
                              Text(
                                'U',
                                style: TextStyle(
                                  fontSize: 22,
                                  decoration: TextDecoration.underline,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 126,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          alignment: Alignment.topLeft,
                          child: TextField(
                            controller: _commentDraftCtrl,
                            maxLines: null,
                            expands: true,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: canAddComment
                                  ? () => _addComment(selected)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 30,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: canAddComment
                                      ? const Color(0xFFF3F4F6)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Add Comment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: canAddComment
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'ALL COMMENTS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                      if (comments.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2BB673),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            comments.length.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 22),
                  if (comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A2B3),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final author =
                            comment['author']?.toString().trim().isNotEmpty ??
                                false
                            ? comment['author'].toString().trim()
                            : 'User';
                        final initial = author.substring(0, 1).toUpperCase();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF2F4F7),
                                border: Border.all(
                                  color: const Color(0xFFE4E7EC),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          color: Color(0xFF98A2B3),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        comment['date']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF98A2B3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      14,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7FB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            comment['message']?.toString() ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () =>
                                              _deleteComment(selected, index),
                                          child: const Icon(
                                            LucideIcons.trash2,
                                            size: 14,
                                            color: Color(0xFF98A2B3),
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
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotePreferencesTab(String label, int index) {
    final isActive = _quotePreferencesTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _quotePreferencesTabIndex = index;
        });
      },
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? const Color(0xFF2A2A2A) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotePreferencesTabBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreferenceCheckboxRow(
          value: _allowEditingAcceptedQuotes,
          onChanged: (value) {
            setState(() {
              _allowEditingAcceptedQuotes = value ?? false;
            });
          },
          title: 'Allow editing of accepted quotes',
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        _buildPreferenceCheckboxRow(
          value: _allowCustomerAcceptance,
          onChanged: (value) {
            setState(() {
              _allowCustomerAcceptance = value ?? false;
            });
          },
          title:
              'Allow customers to accept or decline the quotes via platforms '
              'like Whatsapp, and public link',
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        const Text(
          'Automate accepted quotes to invoices conversion',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<int>(
          groupValue: _acceptedQuoteConversionMode,
          onChanged: (next) {
            setState(() {
              _acceptedQuoteConversionMode = next ?? 0;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreferenceRadioRow(
                value: 0,
                label: 'Don\'t convert accepted quotes automatically',
              ),
              _buildPreferenceRadioRow(
                value: 1,
                label: 'Convert accepted quotes to draft invoices',
                helper: '(Invoice will be saved as a draft.)',
              ),
              _buildPreferenceRadioRow(
                value: 2,
                label:
                    'Convert accepted quotes to invoices and email it to the customer',
                helper: '(Invoice will be sent to your customer.)',
              ),
            ],
          ),
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        const Text(
          'Zero-Value Line Items',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        _buildPreferenceCheckboxRow(
          value: _hideZeroValueLineItems,
          onChanged: (value) {
            setState(() {
              _hideZeroValueLineItems = value ?? false;
            });
          },
          title: 'Hide zero-value line items',
          helper:
              'Choose whether you want to hide zero-value line items in a '
              'quote\'s PDF and the Customer Portal. They will still be '
              'visible while editing a quote. This setting will not apply to '
              'quotes whose total is zero.',
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        const Text(
          'Select the fields in a quote that you\'d like to retain when you '
          'convert it into a sales order or invoice.',
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
        ),
        const SizedBox(height: 14),
        _buildPreferenceCheckboxRow(
          value: _retainCustomerNotes,
          onChanged: (value) {
            setState(() {
              _retainCustomerNotes = value ?? false;
            });
          },
          title: 'Customer Notes',
          dense: true,
        ),
        _buildPreferenceCheckboxRow(
          value: _retainTermsConditions,
          onChanged: (value) {
            setState(() {
              _retainTermsConditions = value ?? false;
            });
          },
          title: 'Terms & Conditions',
          dense: true,
        ),
        _buildPreferenceCheckboxRow(
          value: _retainAddress,
          onChanged: (value) {
            setState(() {
              _retainAddress = value ?? false;
            });
          },
          title: 'Address',
          dense: true,
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 224,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6DDE6)),
          ),
          child: TextField(
            controller: _quotePreferencesTermsCtrl,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(height: 36),
        const Text(
          'Customer Notes',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 224,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6DDE6)),
          ),
          child: TextField(
            controller: _quotePreferencesNotesCtrl,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        const Divider(height: 36, color: Color(0xFFE5E7EB)),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: () {
              ZerpaiToast.success(context, 'Quote preferences saved');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteFieldsTabBody() {
    final rows = [
      ('Terms & Conditions', 'Text Box (Multi-line)', 'No', 'Yes', 'Active'),
      ('Salesperson', 'Text Box (Single Line)', 'No', 'Yes', 'Active'),
      ('Subject', 'Text Box (Single Line)', 'No', 'Yes', 'Active'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                ZerpaiToast.info(
                  context,
                  'New field creation is not configured yet',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'New',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Container(
                height: 54,
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 32,
                      child: Text(
                        'FIELD NAME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 28,
                      child: Text(
                        'DATA TYPE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 16,
                      child: Text(
                        'MANDATORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Text(
                        'SHOW IN ALL\nPDFS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
              ),
              for (final row in rows) ...[
                _QuotePreferenceFieldRow(
                  fieldName: row.$1,
                  dataType: row.$2,
                  mandatory: row.$3,
                  showInAllPdfs: row.$4,
                  status: row.$5,
                ),
                if (row != rows.last)
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    String? helper,
    bool dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 2 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Color(0xFFCAD5E2)),
              activeColor: const Color(0xFF4C8BF5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.45,
                    ),
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helper,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRadioRow({
    required int value,
    required String label,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<int>(
            value: value,
            activeColor: const Color(0xFF4C8BF5),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: label),
                    if (helper != null)
                      TextSpan(
                        text: ' $helper',
                        style: const TextStyle(color: Color(0xFF667085)),
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

  Future<Uint8List> _buildPrintableQuotationPdf(
    _QuoteOverviewRecord quote,
    dynamic org,
  ) async {
    pw.ThemeData? theme;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Inter-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      theme = pw.ThemeData.withFont(
        base: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (e) {
      debugPrint('Failed to load PDF fonts: $e');
    }

    final logoImage = await _loadQuotationPdfLogo(org?.logoUrl?.toString());
    final doc = pw.Document(theme: theme);
    final companyName = (org?.name?.toString().trim().isNotEmpty ?? false)
        ? org.name.toString().trim().toUpperCase()
        : '-';
    final noteText = quote.notes.trim().isEmpty ? '-' : quote.notes.trim();
    final orgProfileLines = _orgProfileLines(org);
    final subTotalValue = _pdfCurrencyLabel(quote.subTotal);
    final cgstValue = _pdfCurrencyLabel(quote.cgst);
    final sgstValue = _pdfCurrencyLabel(quote.sgst);
    final roundOffValue = _pdfCurrencyLabel(quote.roundOff);
    final totalValue = _pdfCurrencyLabel(quote.total);
    final totalNumeric = _parseCurrencyValue(quote.total);
    final cgstNumeric = _parseCurrencyValue(quote.cgst);
    final sgstNumeric = _parseCurrencyValue(quote.sgst);
    final cgstRate = _formatPdfTaxRate(
      quote.items.isEmpty || totalNumeric <= 0
          ? 0
          : (cgstNumeric / totalNumeric) * 100,
    );
    final sgstRate = _formatPdfTaxRate(
      quote.items.isEmpty || totalNumeric <= 0
          ? 0
          : (sgstNumeric / totalNumeric) * 100,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  height: 118,
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 156,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.fromLTRB(10, 18, 10, 34),
                          child: _buildQuotationPdfLogoWidget(logoImage),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 2),
                          child: pw.Stack(
                            children: [
                              pw.Align(
                                alignment: pw.Alignment.topCenter,
                                child: pw.Text(
                                  companyName,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Positioned(
                                top: 22,
                                left: 0,
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < orgProfileLines.length;
                                      i++
                                    ) ...[
                                      pw.Text(
                                        orgProfileLines[i],
                                        style: const pw.TextStyle(
                                          fontSize: 9.5,
                                        ),
                                      ),
                                      if (i != orgProfileLines.length - 1)
                                        pw.SizedBox(height: 2),
                                    ],
                                  ],
                                ),
                              ),
                              pw.Positioned(
                                right: 0,
                                bottom: 10,
                                child: pw.Text(
                                  'QUOTE',
                                  style: pw.TextStyle(
                                    fontSize: 23,
                                    fontWeight: pw.FontWeight.normal,
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
                pw.Container(
                  height: 46,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
                      bottom: pw.BorderSide(
                        color: PdfColors.grey500,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey500,
                                width: 0.8,
                              ),
                            ),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '#',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                              pw.Spacer(),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    ': ${quote.id}',
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    ': ${quote.date}',
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Place Of Supply',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                ': ${quote.placeOfSupply} (32)',
                                style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  height: 60,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey500,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(6, 2, 6, 0),
                        child: pw.Text(
                          'Bill To',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 0),
                        child: pw.Text(
                          quote.customerName,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColors.blue700,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(6, 2, 6, 0),
                        child: pw.Text(
                          quote.customerEmail.isEmpty
                              ? 'GSTIN 32ABACS3075R1ZX'
                              : quote.customerEmail,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey500,
                    width: 0.8,
                  ),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(32),
                    1: pw.FlexColumnWidth(4.2),
                    2: pw.FlexColumnWidth(1.35),
                    3: pw.FlexColumnWidth(1.0),
                    4: pw.FlexColumnWidth(1.1),
                    5: pw.FlexColumnWidth(0.65),
                    6: pw.FlexColumnWidth(0.85),
                    7: pw.FlexColumnWidth(0.65),
                    8: pw.FlexColumnWidth(0.85),
                    9: pw.FlexColumnWidth(1.45),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _pwTableCell('#', bold: true, center: true),
                        _pwTableCell('Item & Description', bold: true),
                        _pwTableCell('HSN/SAC', bold: true, center: true),
                        _pwTableCell('Qty', bold: true, center: true),
                        _pwTableCell('Rate', bold: true, right: true),
                        _pwTableCell('CGST', bold: true, center: true),
                        _pwTableCell('', bold: true, center: true),
                        _pwTableCell('SGST', bold: true, center: true),
                        _pwTableCell('', bold: true, center: true),
                        _pwTableCell('Amount', bold: true, right: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _pwTableCell('', bold: true, center: true),
                        _pwTableCell('', bold: true),
                        _pwTableCell('', bold: true, center: true),
                        _pwTableCell('', bold: true, center: true),
                        _pwTableCell('', bold: true, right: true),
                        _pwTableCell('%', bold: true, center: true),
                        _pwTableCell('Amt', bold: true, center: true),
                        _pwTableCell('%', bold: true, center: true),
                        _pwTableCell('Amt', bold: true, center: true),
                        _pwTableCell('', bold: true, right: true),
                      ],
                    ),
                    ...quote.items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return pw.TableRow(
                        children: [
                          _pwTableCell('${idx + 1}', center: true),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 6,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    fontSize: 10.25,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (item.description.trim().isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 3),
                                    child: pw.Text(
                                      item.description,
                                      style: const pw.TextStyle(fontSize: 8.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _pwTableCell(item.hsnSac, center: true),
                          _pwTableCell(
                            '${_pdfQuantityLabel(item.quantity)}\n${item.unit}',
                            center: true,
                          ),
                          _pwTableCell(
                            _pdfNumericLabel(item.price),
                            right: true,
                          ),
                          _pwTableCell(cgstRate, center: true),
                          _pwTableCell(
                            _pdfProportionalTax(
                              item.amount,
                              cgstNumeric,
                              totalNumeric,
                            ),
                            center: true,
                          ),
                          _pwTableCell(sgstRate, center: true),
                          _pwTableCell(
                            _pdfProportionalTax(
                              item.amount,
                              sgstNumeric,
                              totalNumeric,
                            ),
                            center: true,
                          ),
                          _pwTableCell(
                            _pdfNumericLabel(item.amount),
                            right: true,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(
                  height: 186,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey500,
                                width: 0.8,
                              ),
                            ),
                          ),
                          padding: const pw.EdgeInsets.fromLTRB(6, 10, 6, 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Total In Words',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                _amountToWords(totalNumeric),
                                style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                              pw.SizedBox(height: 22),
                              pw.Text(
                                'Notes',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                noteText,
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 304,
                        child: pw.Column(
                          children: [
                            pw.Expanded(
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(
                                  8,
                                  10,
                                  8,
                                  8,
                                ),
                                child: pw.Column(
                                  children: [
                                    _pwSummaryRow('Sub Total', subTotalValue),
                                    _pwSummaryRow(
                                      'CGST$cgstRate ($cgstRate)',
                                      cgstValue,
                                    ),
                                    _pwSummaryRow(
                                      'SGST$sgstRate ($sgstRate)',
                                      sgstValue,
                                    ),
                                    _pwSummaryRow('Rounding', roundOffValue),
                                    pw.SizedBox(height: 4),
                                    _pwSummaryRow(
                                      'Total',
                                      totalValue,
                                      bold: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            pw.Container(
                              height: 30,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  top: pw.BorderSide(
                                    color: PdfColors.grey500,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              alignment: pw.Alignment.bottomCenter,
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Text(
                                'Authorized Signature',
                                style: pw.TextStyle(fontSize: 9.5),
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
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pwTableCell(
    String text, {
    bool bold = false,
    bool center = false,
    bool right = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: center
            ? pw.TextAlign.center
            : right
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
          height: 1.1,
        ),
      ),
    );
  }

  Future<pw.ImageProvider?> _loadQuotationPdfLogo(String? logoUrl) async {
    if (logoUrl == null || logoUrl.trim().isEmpty) return null;
    try {
      return await networkImage(logoUrl.trim());
    } catch (e) {
      debugPrint('Failed to load quotation PDF logo: $e');
      return null;
    }
  }

  pw.Widget _buildQuotationPdfLogoWidget(pw.ImageProvider? logoImage) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(2),
      child: logoImage != null
          ? pw.Image(logoImage, fit: pw.BoxFit.contain)
          : pw.Container(
              color: PdfColors.black,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'IMAGE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
    );
  }

  pw.Widget _pwSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _pdfCurrencyLabel(String value) {
    final numeric = _parseCurrencyValue(value);
    return 'Rs. ${NumberFormat('#,##,##0.00').format(numeric)}';
  }

  String _pdfNumericLabel(String value) {
    return NumberFormat('#,##,##0.00').format(_parseCurrencyValue(value));
  }

  String _pdfQuantityLabel(String value) {
    final quantity = double.tryParse(value.trim());
    if (quantity == null) return value;
    if ((quantity - quantity.roundToDouble()).abs() < 0.001) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toStringAsFixed(2);
  }

  // ignore: unused_element
  String _pdfCurrencyText(String value) {
    return _formatCurrency(
      _parseCurrencyValue(value),
    ).replaceAll('â‚¹', 'Rs. ');
  }

  // ignore: unused_element
  String _pdfNumericText(String value) {
    return _formatCurrency(
      _parseCurrencyValue(value),
    ).replaceAll('â‚¹', '').trim();
  }

  double _parseCurrencyValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _pdfProportionalTax(
    String itemAmount,
    double taxValue,
    double totalValue,
  ) {
    if (taxValue <= 0 || totalValue <= 0) return '0.00';
    final itemTotal = _parseCurrencyValue(itemAmount);
    return ((itemTotal / totalValue) * taxValue).toStringAsFixed(2);
  }

  String _formatPdfTaxRate(double value) {
    if (value <= 0) return '0%';
    if ((value - value.roundToDouble()).abs() < 0.001) {
      return '${value.round()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _amountToWords(double amount) {
    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();
    final rupeeWords = _numberToWords(rupees);
    if (paise == 0) {
      return 'Indian Rupee $rupeeWords Only';
    }
    return 'Indian Rupee $rupeeWords and ${_numberToWords(paise)} Paise Only';
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';

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

    String belowThousand(int value) {
      final parts = <String>[];
      if (value >= 100) {
        parts.add('${ones[value ~/ 100]} Hundred');
        value %= 100;
      }
      if (value >= 20) {
        parts.add(tens[value ~/ 10]);
        if (value % 10 != 0) {
          parts.add(ones[value % 10]);
        }
      } else if (value > 0) {
        parts.add(ones[value]);
      }
      return parts.join(' ').trim();
    }

    final parts = <String>[];
    final crores = number ~/ 10000000;
    final lakhs = (number % 10000000) ~/ 100000;
    final thousands = (number % 100000) ~/ 1000;
    final remainder = number % 1000;

    if (crores > 0) parts.add('${belowThousand(crores)} Crore');
    if (lakhs > 0) parts.add('${belowThousand(lakhs)} Lakh');
    if (thousands > 0) parts.add('${belowThousand(thousands)} Thousand');
    if (remainder > 0) parts.add(belowThousand(remainder));

    return parts.join(' ').trim();
  }

  IconData _getIconForMenuItem(String item) {
    switch (item) {
      case 'Send Email':
        return LucideIcons.mail;
      case 'Send SMS':
        return LucideIcons.messageSquare;
      case 'PDF':
      case 'View PDF':
      case 'Download PDF':
        return LucideIcons.fileText;
      case 'Print':
        return LucideIcons.printer;
      case 'Convert to Invoice':
        return LucideIcons.fileText;
      case 'Convert to Sales Order':
        return LucideIcons.shoppingCart;
      case 'Create Project':
        return LucideIcons.folderPlus;
      case 'Mark as Accepted':
        return LucideIcons.checkCircle2;
      case 'Mark as Declined':
        return LucideIcons.xCircle;
      case 'Clone':
        return LucideIcons.copy;
      case 'Delete':
        return LucideIcons.trash2;
      case 'Quote Preferences':
        return LucideIcons.settings;
      case 'Invoice':
        return LucideIcons.fileText;
      case 'Sales Order':
        return LucideIcons.shoppingCart;
      default:
        return LucideIcons.helpCircle;
    }
  }

  Widget _buildDropdownMenuItem(
    BuildContext context,
    String item,
    VoidCallback onTap, {
    bool showIcon = true,
  }) {
    bool isHovered = false;
    return MenuItemButton(
      onPressed: onTap,
      style: MenuItemButton.styleFrom(padding: EdgeInsets.zero).copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: StatefulBuilder(
        builder: (context, setOverlayState) {
          return MouseRegion(
            onEnter: (_) => setOverlayState(() => isHovered = true),
            onExit: (_) => setOverlayState(() => isHovered = false),
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (showIcon) ...[
                    Icon(
                      _getIconForMenuItem(item),
                      size: 15,
                      color: isHovered ? Colors.white : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isHovered
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuButton(IconData icon, String label, List<String> items) {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      menuChildren: items
          .map(
            (item) => _buildDropdownMenuItem(
              context,
              item,
              () => _handleMenuAction(item),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuIconOnly(List<String> items) {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      menuChildren: items
          .map(
            (item) => _buildDropdownMenuItem(
              context,
              item,
              () => _handleMenuAction(item),
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
        );
      },
    );
  }

  Widget _greenMenuButton(
    String label,
    List<String> items, {
    IconData? icon,
    bool compact = false,
  }) {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      menuChildren: items
          .map(
            (item) => _buildDropdownMenuItem(
              context,
              item,
              () => _handleMenuAction(item),
              showIcon: false,
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: compact ? 36 : 30,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(compact ? 0 : 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _whiteMenuButton(String label, List<String> items) {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      menuChildren: items
          .map(
            (item) => _buildDropdownMenuItem(
              context,
              item,
              () => _handleMenuAction(item),
              showIcon: false,
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 22, color: const Color(0xFFE5E7EB));
  }

  Widget _topSquareButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
    Color? borderColor,
    int badgeCount = 0,
  }) {
    final hasCount = badgeCount > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        constraints: BoxConstraints(minWidth: hasCount ? 46 : 38),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor ?? background),
        ),
        padding: EdgeInsets.symmetric(horizontal: hasCount ? 6 : 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            if (hasCount) ...[
              const SizedBox(width: 5),
              Container(width: 1, height: 14, color: const Color(0xFFE5E7EB)),
              const SizedBox(width: 5),
              Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344054),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showShareQuoteLinkDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(top: 0, left: 16, right: 16),
          alignment: Alignment.topCenter,
          child: _ShareQuoteLinkDialog(quoteId: _selectedQuote.id),
        );
      },
    );
  }
}

class _QuoteOverviewRecord {
  final String? dbId;
  final String id;
  final String customerName;
  final String date;
  final String status;
  final String amount;
  final String location;
  final String placeOfSupply;
  final String salesperson;
  final String billingAddress;
  final String shippingAddress;
  final String customerEmail;
  final String notes;
  final String terms;
  final String subTotal;
  final String cgst;
  final String sgst;
  final String adjustment;
  final String roundOff;
  final String total;
  final int attachmentCount;
  final String statusLabel;
  final List<_QuoteItem> items;
  final List<_QuoteActivity> activities;
  final Map<String, dynamic>? clonePayload;

  const _QuoteOverviewRecord({
    this.dbId,
    required this.id,
    required this.customerName,
    required this.date,
    required this.status,
    required this.amount,
    required this.location,
    required this.placeOfSupply,
    required this.salesperson,
    required this.billingAddress,
    required this.shippingAddress,
    required this.customerEmail,
    required this.notes,
    required this.terms,
    required this.subTotal,
    required this.cgst,
    required this.sgst,
    required this.adjustment,
    required this.roundOff,
    required this.total,
    this.attachmentCount = 0,
    required this.statusLabel,
    required this.items,
    required this.activities,
    this.clonePayload,
  });
}

class _OverviewViewOptionRow extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _OverviewViewOptionRow({
    required this.label,
    required this.isSelected,
    required this.isStarred,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_OverviewViewOptionRow> createState() => _OverviewViewOptionRowState();
}

class _OverviewViewOptionRowState extends State<_OverviewViewOptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.isSelected
        ? const Color(0xFFF3F6FD)
        : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: background,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onStarTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    widget.isStarred ? Icons.star : Icons.star_border,
                    size: 14,
                    color: const Color(0xFFD1D5DB),
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

class _QuoteItem {
  final String name;
  final String description;
  final String quantity;
  final String unit;
  final String price;
  final String discount;
  final String amount;
  final String hsnSac;
  final String? productId;
  final String? taxId;
  final String? warehouseId;
  final String? discountType;
  final double? rateValue;
  final double? quantityValue;
  final double? discountValue;

  const _QuoteItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.discount,
    required this.amount,
    required this.hsnSac,
    this.productId,
    this.taxId,
    this.warehouseId,
    this.discountType,
    this.rateValue,
    this.quantityValue,
    this.discountValue,
  });
}

class _QuoteActivity {
  final String time;
  final String message;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  const _QuoteActivity({
    required this.time,
    required this.message,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });
}

class _PdfCell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool center;
  final bool right;

  const _PdfCell(
    this.text, {
    this.bold = false,
    this.center = false,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontFamily: _pdfFontFamily,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: Colors.black,
          height: 1.1,
        ),
      ),
    );
  }
}

class _QuotePreferenceFieldRow extends StatefulWidget {
  final String fieldName;
  final String dataType;
  final String mandatory;
  final String showInAllPdfs;
  final String status;

  const _QuotePreferenceFieldRow({
    required this.fieldName,
    required this.dataType,
    required this.mandatory,
    required this.showInAllPdfs,
    required this.status,
  });

  @override
  State<_QuotePreferenceFieldRow> createState() =>
      _QuotePreferenceFieldRowState();
}

class _QuotePreferenceFieldRowState extends State<_QuotePreferenceFieldRow> {
  bool _isHovered = false;

  Widget _buildActionMenuItem(String label, VoidCallback onTap) {
    bool isHovered = false;
    return MenuItemButton(
      onPressed: onTap,
      style: MenuItemButton.styleFrom(padding: EdgeInsets.zero).copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: StatefulBuilder(
        builder: (context, setOverlayState) {
          return MouseRegion(
            onEnter: (_) => setOverlayState(() => isHovered = true),
            onExit: (_) => setOverlayState(() => isHovered = false),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF4A8DF6) : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isHovered ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                flex: 32,
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 15,
                      color: Color(0xFF111827),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.fieldName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 28,
                child: Text(
                  widget.dataType,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ),
              Expanded(
                flex: 16,
                child: Text(
                  widget.mandatory,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ),
              Expanded(
                flex: 18,
                child: Text(
                  widget.showInAllPdfs,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  widget.status,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Center(
                  child: MenuAnchor(
                    style: const MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.white),
                      surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                      elevation: WidgetStatePropertyAll(10),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 4),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    menuChildren: [
                      _buildActionMenuItem(
                        'Hide in all PDF',
                        () => Navigator.of(context).maybePop(),
                      ),
                      _buildActionMenuItem(
                        'Mark As Mandatory',
                        () => Navigator.of(context).maybePop(),
                      ),
                    ],
                    builder: (context, controller, child) {
                      return InkWell(
                        onTap: () => controller.isOpen
                            ? controller.close()
                            : controller.open(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.chevronDown,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
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

class _PdfItemCell extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PdfItemCell({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: _pdfFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: _pdfFontFamily,
              fontSize: 11,
              color: Colors.black,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PdfSummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: _pdfFontFamily,
                fontSize: 11,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: Colors.black,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 78,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: _pdfFontFamily,
                fontSize: 11,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: Colors.black,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareQuoteLinkDialog extends StatefulWidget {
  final String quoteId;
  const _ShareQuoteLinkDialog({required this.quoteId});

  @override
  State<_ShareQuoteLinkDialog> createState() => _ShareQuoteLinkDialogState();
}

class _ShareQuoteLinkDialogState extends State<_ShareQuoteLinkDialog> {
  bool _isPublic = true;
  bool _linkGenerated = false;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 80));
  final GlobalKey _dateFieldKey = GlobalKey();
  final LayerLink _dateFieldLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final String origin = Uri.base.origin;
    final String generatedLink =
        origin +
        "/#/books/zabnixprivatelimited/secure?CEstimateID=" +
        widget.quoteId;

    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Quote Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visibility Row
                Row(
                  children: [
                    const Text(
                      'Visibility: ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    _buildVisibilitySelector(),
                  ],
                ),
                const SizedBox(height: 18),

                if (_isPublic) ...[
                  // Public Mode content
                  const Text(
                    'Select an expiration date and generate the link to share it with your customer. Remember that anyone who has access to this link can view, print or download it.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Link Expiration Date*',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Date Field
                  CompositedTransformTarget(
                    link: _dateFieldLink,
                    child: InkWell(
                      key: _dateFieldKey,
                      onTap: _selectExpirationDate,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd-MM-yyyy').format(_expirationDate),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Note row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        LucideIcons.info,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'By default, the link is set to expire 80 days from the quote expiry date.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (_linkGenerated) ...[
                    // Generated Link box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        generatedLink,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (!_linkGenerated) {
                            setState(() {
                              _linkGenerated = true;
                            });
                          } else {
                            Clipboard.setData(
                              ClipboardData(text: generatedLink),
                            );
                            ZerpaiToast.success(
                              context,
                              'Link copied to clipboard successfully',
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _linkGenerated ? 'Copy Link' : 'Generate Link',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!_linkGenerated) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            ZerpaiToast.success(
                              context,
                              'All active links disabled successfully',
                            );
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Disable All Active Links',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // Private & Secure Mode content
                  const Text(
                    'You can share the quote privately only through Customer Portal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Portal missing warning box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.info,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E3A8A),
                                    height: 1.5,
                                    fontFamily: 'Inter',
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "It seems like you haven't enabled ",
                                    ),
                                    TextSpan(
                                      text: "Customer Portal",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          " for your customer or some of your contact persons. Enable Customer Portal for your customer or contact persons and they will be able to view the quote privately in Customer Portal.",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Learn more about Customer Portal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                    decoration: TextDecoration.underline,
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
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ZerpaiToast.info(
                            context,
                            'Redirecting to Customer Setup...',
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Go To Customers',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isPublic ? 'Public' : 'Private & Secure',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Color(0xFFF97316),
              ),
            ],
          ),
        );
      },
      menuChildren: [
        _buildVisibilityOption(
          'Public',
          'Anyone with the link can access the complete quote before its expiration date.',
          true,
        ),
        _buildVisibilityOption(
          'Private & Secure',
          'Your customer can access the quote only from the Customer Portal.',
          false,
        ),
      ],
    );
  }

  Widget _buildVisibilityOption(
    String title,
    String description,
    bool isPublicOption,
  ) {
    bool isHovered = false;
    return MenuItemButton(
      onPressed: () {
        setState(() {
          _isPublic = isPublicOption;
        });
      },
      style: MenuItemButton.styleFrom(padding: EdgeInsets.zero).copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: StatefulBuilder(
        builder: (context, setOverlayState) {
          return MouseRegion(
            onEnter: (_) => setOverlayState(() => isHovered = true),
            onExit: (_) => setOverlayState(() => isHovered = false),
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isHovered ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHovered
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _expirationDate,
      targetKey: _dateFieldKey,
      targetLink: _dateFieldLink,
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }
}

class SalesQuotationEmailScreen extends ConsumerStatefulWidget {
  final String quoteId;
  const SalesQuotationEmailScreen({super.key, required this.quoteId});

  @override
  ConsumerState<SalesQuotationEmailScreen> createState() =>
      _SalesQuotationEmailScreenState();
}

class _SalesQuotationEmailScreenState
    extends ConsumerState<SalesQuotationEmailScreen> {
  final _bodyCtrl = TextEditingController();
  bool _isLoading = true;
  _QuoteOverviewRecord? _quote;
  String? _quoteDbId;

  @override
  void initState() {
    super.initState();
    _loadQuoteData();
  }

  Future<void> _loadQuoteData() async {
    try {
      final supabase = Supabase.instance.client;
      Map<String, dynamic>? dbQuote;
      try {
        dbQuote = await supabase
            .from('sales_quotations')
            .select('*, customer:customers(display_name, email)')
            .eq('id', widget.quoteId)
            .maybeSingle();
      } catch (_) {}

      dbQuote ??= await supabase
          .from('sales_quotations')
          .select('*, customer:customers(display_name, email)')
          .eq('quotation_number', widget.quoteId)
          .maybeSingle();

      if (dbQuote != null) {
        final total = _quoteNum(dbQuote['grand_total']);
        final subTotal = _quoteNum(dbQuote['subtotal']);
        final halfTax = _quoteNum(dbQuote['tax_total']) / 2;
        final quoteDate = dbQuote['quotation_date']?.toString();
        final parsedDate = quoteDate != null
            ? DateTime.tryParse(quoteDate)
            : null;

        if (!mounted) return;
        setState(() {
          _quoteDbId = (dbQuote!['id'] ?? '').toString();
          _quote = _QuoteOverviewRecord(
            id: (dbQuote['quotation_number'] ?? dbQuote['id'] ?? '').toString(),
            customerName: _quoteCustomerDisplayName(dbQuote['customer']),
            date: parsedDate != null
                ? DateFormat('dd-MM-yyyy').format(parsedDate)
                : '',
            status: (dbQuote['status'] ?? 'Draft').toString().toUpperCase(),
            amount: _emailCurrency(total),
            location:
                (dbQuote['place_of_supply']?.toString().trim().isNotEmpty ??
                    false)
                ? dbQuote['place_of_supply'].toString().trim()
                : '-',
            placeOfSupply:
                (dbQuote['place_of_supply']?.toString().trim().isNotEmpty ??
                    false)
                ? dbQuote['place_of_supply'].toString().trim()
                : '-',
            salesperson:
                dbQuote['salesperson_id']?.toString().trim().isNotEmpty == true
                ? dbQuote['salesperson_id'].toString().trim()
                : '-',
            billingAddress: '-',
            shippingAddress: '-',
            customerEmail: _quoteCustomerEmail(dbQuote['customer']),
            notes: dbQuote['customer_notes'] ?? '',
            terms: dbQuote['terms_and_conditions'] ?? '-',
            subTotal: _emailCurrency(subTotal),
            cgst: _emailCurrency(halfTax),
            sgst: _emailCurrency(halfTax),
            adjustment: _quoteNum(dbQuote['adjustment']).toStringAsFixed(2),
            roundOff: _emailCurrency(0),
            total: _emailCurrency(total),
            statusLabel: _emailStatusLabel(
              (dbQuote['status'] ?? 'Draft').toString(),
            ),
            items: [
              _QuoteItem(
                name:
                    dbQuote['reference_number']?.toString().trim().isNotEmpty ==
                        true
                    ? dbQuote['reference_number'].toString().trim()
                    : '-',
                description: dbQuote['customer_notes']?.toString().trim() ?? '',
                quantity: '1',
                unit: 'pcs',
                price: _emailCurrency(total),
                discount: '-',
                amount: _emailCurrency(total),
                hsnSac: '',
              ),
            ],
            activities: const [],
          );
          _bodyCtrl.text =
              'Thank you for contacting us. Your quote can be viewed, printed and downloaded as PDF from the link below.';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading quotation from DB: $e');
    }

    try {
      final quotes = await ref.read(salesQuotesProvider.future);
      final providerMatch = quotes.cast<dynamic>().where((quote) {
        return quote.id == widget.quoteId || quote.saleNumber == widget.quoteId;
      }).toList();

      if (providerMatch.isNotEmpty) {
        final q = providerMatch.first;
        final total = q.total as double;
        final subTotal = q.subTotal as double;
        final halfTax = (q.taxTotal as double) / 2;

        if (!mounted) return;
        setState(() {
          _quoteDbId = q.id as String;
          _quote = _QuoteOverviewRecord(
            id: q.saleNumber as String,
            customerName: q.customer?.displayName?.trim().isNotEmpty == true
                ? q.customer!.displayName.trim()
                : '-',
            date: DateFormat('dd-MM-yyyy').format(q.saleDate as DateTime),
            status: (q.status as String).toUpperCase(),
            amount: _emailCurrency(total),
            location: (q.placeOfSupply?.toString().trim().isNotEmpty ?? false)
                ? q.placeOfSupply.toString().trim()
                : '-',
            placeOfSupply:
                (q.placeOfSupply?.toString().trim().isNotEmpty ?? false)
                ? q.placeOfSupply.toString().trim()
                : '-',
            salesperson: (q.salesperson?.toString().trim().isNotEmpty ?? false)
                ? q.salesperson.toString().trim()
                : '-',
            billingAddress: '-',
            shippingAddress: '-',
            customerEmail: q.customer?.email ?? '',
            notes: (q.customerNotes?.toString().trim().isNotEmpty ?? false)
                ? q.customerNotes.toString().trim()
                : '-',
            terms: (q.termsAndConditions?.toString().trim().isNotEmpty ?? false)
                ? q.termsAndConditions.toString().trim()
                : '-',
            subTotal: _emailCurrency(subTotal),
            cgst: _emailCurrency(halfTax),
            sgst: _emailCurrency(halfTax),
            adjustment: (q.adjustment as double).toStringAsFixed(2),
            roundOff: _emailCurrency(0),
            total: _emailCurrency(total),
            statusLabel: _emailStatusLabel(q.status as String),
            items: [
              _QuoteItem(
                name: q.reference?.toString().trim().isNotEmpty == true
                    ? q.reference.toString().trim()
                    : '-',
                description: q.customerNotes?.toString().trim() ?? '',
                quantity: '1',
                unit: 'pcs',
                price: _emailCurrency(total),
                discount: '-',
                amount: _emailCurrency(total),
                hsnSac: '-',
              ),
            ],
            activities: const [],
          );
          _bodyCtrl.text =
              'Thank you for contacting us. Your quote can be viewed, printed and downloaded as PDF from the link below.';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading quotation email data from provider: $e');
    }

    if (widget.quoteId.length > 10) {
      try {
        final supabase = Supabase.instance.client;
        final q = await supabase
            .from('sales_quotations')
            .select('*, customer:customers(display_name, email)')
            .eq('id', widget.quoteId)
            .single();

        setState(() {
          _quoteDbId = (q['id'] ?? '').toString();
          _quote = _QuoteOverviewRecord(
            id: (q['quotation_number'] ?? q['id'] ?? '').toString(),
            customerName: q['customer']?['display_name'] ?? '-',
            date: q['quotation_date'] ?? '',
            status: (q['status'] ?? 'Draft').toString().toUpperCase(),
            amount: '₹${q['grand_total'] ?? '0.00'}',
            location:
                (q['place_of_supply']?.toString().trim().isNotEmpty ?? false)
                ? q['place_of_supply'].toString().trim()
                : '-',
            placeOfSupply:
                (q['place_of_supply']?.toString().trim().isNotEmpty ?? false)
                ? q['place_of_supply'].toString().trim()
                : '-',
            salesperson:
                q['salesperson_id']?.toString().trim().isNotEmpty == true
                ? q['salesperson_id'].toString().trim()
                : '-',
            billingAddress: '-',
            shippingAddress: '-',
            customerEmail: q['customer']?['email'] ?? '',
            notes: q['customer_notes'] ?? '',
            terms: q['terms_and_conditions'] ?? '-',
            subTotal: '₹${q['subtotal'] ?? '0.00'}',
            cgst: '₹0.00',
            sgst: '₹0.00',
            adjustment: q['adjustment']?.toString() ?? '0',
            roundOff: '₹${q['roundoff'] ?? '0.00'}',
            total: '₹${q['grand_total'] ?? '0.00'}',
            statusLabel: q['status'] ?? 'Draft',
            items: [
              _QuoteItem(
                name: '-',
                description: '',
                quantity: '1',
                unit: 'pcs',
                price: '₹${q['grand_total'] ?? '0.00'}',
                discount: '-',
                amount: '₹${q['grand_total'] ?? '0.00'}',
                hsnSac: '',
              ),
            ],
            activities: const [],
          );
          _bodyCtrl.text =
              'Thank you for contacting us. Your quote can be viewed, printed and downloaded as PDF from the link below.';
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('Error loading quotation from DB: $e');
      }
    }

    setState(() {
      _quoteDbId = null;
      _quote =
          _quote ??
          const _QuoteOverviewRecord(
            id: '',
            customerName: '-',
            date: '',
            status: 'DRAFT',
            amount: '₹0.00',
            location: '-',
            placeOfSupply: '-',
            salesperson: '-',
            billingAddress: '-',
            shippingAddress: '-',
            customerEmail: '',
            notes: '-',
            terms: '-',
            subTotal: '₹0.00',
            cgst: '₹0.00',
            sgst: '₹0.00',
            adjustment: '0.00',
            roundOff: '₹0.00',
            total: '₹0.00',
            statusLabel: 'Draft',
            items: <_QuoteItem>[],
            activities: <_QuoteActivity>[],
          );
      _bodyCtrl.text =
          'Thank you for contacting us. Your quote can be viewed, printed and downloaded as PDF from the link below.';

      _isLoading = false;
    });
  }

  String _emailCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(value);
  }

  String _emailStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Widget _buildEmailBodyPreview(_QuoteOverviewRecord q, String orgName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company name header
          Text(
            orgName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          // Blue banner container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(color: Color(0xFF3B82F6)),
            alignment: Alignment.center,
            child: Text(
              'Quote #${q.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Dear ${q.customerName},',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyCtrl,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Quote summary beige box
          Center(
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'QUOTE AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF78350F),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.total,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFFDE68A), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quote No',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        q.id,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quote Date',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        q.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // View Quote green button
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'VIEW QUOTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Regards,',
            style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 4),
          Text(
            orgName.toLowerCase().replaceAll(' ', ''),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            orgName,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _quote!;
    final customerName = q.customerName;
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'Our Organization';
    final orgEmail = orgSettings?.email?.trim().isNotEmpty == true
        ? orgSettings!.email!.trim()
        : 'org@example.com';

    return EmailComposerScreen(
      title: 'Email To $customerName',
      initialFrom: '$orgName <$orgEmail>',
      initialTo: '$customerName <${q.customerEmail}>',
      initialSubject: 'Quote - ${q.id} is awaiting your approval',
      initialBody: _bodyCtrl.text,
      attachmentName: '${q.id}.pdf',
      attachmentLabel: 'Attach Quote PDF',
      customPreview: _buildEmailBodyPreview(q, orgName),
      onCancel: () async {
        try {
          if (_quoteDbId != null && _quoteDbId!.isNotEmpty) {
            final supabase = Supabase.instance.client;
            await supabase
                .from('sales_quotations')
                .update({'status': 'draft'})
                .eq('id', _quoteDbId!);
          }

          ref.invalidate(salesQuotesProvider);
        } catch (e) {
          if (context.mounted) {
            ZerpaiToast.error(context, 'Failed to revert quote to draft: $e');
          }
        }

        if (context.mounted) {
          context.go(AppRoutes.salesQuotations);
        }
      },
      onSend: (from, to, subject, body, attachPdf) async {
        try {
          final user = ref.read(authUserProvider);
          final supabase = Supabase.instance.client;
          if (_quoteDbId != null && _quoteDbId!.isNotEmpty) {
            await supabase
                .from('sales_quotations')
                .update({'status': 'sent'})
                .eq('id', _quoteDbId!);

            await supabase.from('sales_quotation_emails').insert({
              'quotation_id': _quoteDbId!,
              'recipient_email': to,
              'subject': subject,
              'message': body,
              'sent_by': user?.id,
            });

            await supabase.from('sales_quotation_activity').insert({
              'quotation_id': _quoteDbId!,
              'action': 'emailed',
              'description': 'Quote emailed to ' + to,
              'performed_by': user?.id,
            });
          }

          ref.invalidate(salesQuotesProvider);

          if (context.mounted) {
            ZerpaiToast.success(context, 'Email sent successfully');
            context.go(AppRoutes.salesQuotations);
          }
        } catch (e) {
          if (context.mounted) {
            ZerpaiToast.error(context, 'Failed to send email: $e');
          }
        }
      },
    );
  }
}
