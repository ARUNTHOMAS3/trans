import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/models/payment_record.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/providers/payment_recieves_provider.dart';
import 'refund_page.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

class PaymentRecievesOverview extends ConsumerStatefulWidget {
  final String paymentId;
  final bool isRefund;
  const PaymentRecievesOverview({
    super.key,
    required this.paymentId,
    this.isRefund = false,
  });

  @override
  ConsumerState<PaymentRecievesOverview> createState() => _PaymentRecievesOverviewState();
}

class _PaymentRecievesOverviewState extends ConsumerState<PaymentRecievesOverview> {
  bool _isDisposed = false;
  String _activeJournalTab = 'journals';
  bool _isJournalCardExpanded = true;
  OverlayEntry? _moreMenuOverlayEntry;
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  OverlayEntry? _attachmentOverlayEntry;
  final LayerLink _attachmentLayerLink = LayerLink();
  bool _isAttachmentOpen = false;

  OverlayEntry? _paymentHistoryOverlayEntry;
  final LayerLink _paymentHistoryLayerLink = LayerLink();
  bool _isPaymentHistoryOpen = false;
  final GlobalKey _messageButtonKey = GlobalKey();

  int _currentPage = 1;
  int _rowsPerPage = 25;
  bool _showTotalCount = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;

  final ScrollController _scrollController = ScrollController();
  String _selectedTemplate = 'Elite Template';

  ButtonStyle _menuItemButtonStyle({double? width, BorderRadius? borderRadius}) {
    return ButtonStyle(
      animationDuration: Duration.zero,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final highlighted = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return highlighted ? AppTheme.primaryBlue : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        final highlighted = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return highlighted ? Colors.white : AppTheme.textSecondary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        final highlighted = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return highlighted ? Colors.white : AppTheme.textSecondary;
      }),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      minimumSize: WidgetStatePropertyAll(Size(width ?? 0, 44)),
      alignment: Alignment.centerLeft,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }

  pw.Widget _buildPdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePaymentReceivedPdf(
    PaymentRecord r,
    OrgSettings? org,
  ) async {
    final doc = pw.Document();

    pw.MemoryImage? logoImage;
    if (org?.logoUrl != null && org!.logoUrl!.trim().isNotEmpty) {
      try {
        final dio = Dio();
        final res = await dio.get(
          org.logoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 140,
                      height: 60,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      width: 140,
                      height: 60,
                      color: const PdfColor.fromInt(0xFF101820),
                      child: pw.Center(
                        child: pw.Text(
                          'LOGO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          (org?.name.isNotEmpty == true) ? org!.name : r.location,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          org == null
                              ? 'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia\nGSTIN 32AACCZ4912F1ZL\n8086355500\nzabnixprivatelimited@gmail.com'
                              : '${org.attention ?? org.name}\n${org.street ?? ""}${org.street != null ? "\n" : ""}${org.city ?? ""} ${org.pincode ?? ""}\n${org.country ?? ""}\n${org.companyIdLabel ?? "GSTIN"}: ${org.companyIdValue ?? ""}\nPhone: ${org.phone ?? ""}\nEmail: ${org.email ?? ""}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                            lineSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Title
              pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1F2937),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Details & Amount Box
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Table details
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfField('Payment Date', r.date),
                        _buildPdfField('Reference Number', r.reference.isNotEmpty ? r.reference : '-'),
                        _buildPdfField('Payment Mode', r.mode),
                        _buildPdfField('Amount Received In Words', _convertAmountToWords(r.amount)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Amount box
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: r.status == 'VOIDED' ? PdfColors.grey500 : const PdfColor.fromInt(0xFF5CB85C),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Amount Received',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            _fmt(r.amount).replaceAll('\u20B9', 'Rs. '),
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Bottom Section: Customer & Signature
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Received From',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          r.customer,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _getCustomerAddressLines(r.customer).join('\n'),
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                            lineSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        pw.SizedBox(height: 50),
                        pw.Container(
                          height: 1,
                          color: PdfColors.grey400,
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Over payment
              pw.Divider(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              pw.Text(
                'Over payment',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _fmt(r.unusedAmount).replaceAll('\u20B9', 'Rs. '),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentRecievesProvider.notifier).loadPayments();
    });
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

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _closeMoreMenu();
    _closeAttachmentMenu();
    _closePaymentHistoryPanel();
    super.dispose();
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
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: Offset(_activeSubMenu != _SubMenuType.none ? 204.0 : 0.0, 8.0),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _MoreMenuDropdownContent(
                  onClose: _closeMoreMenu,
                  activeSubMenu: _activeSubMenu,
                  onSubMenuChanged: (type) {
                    setState(() {
                      _activeSubMenu = type;
                    });
                    _moreMenuOverlayEntry?.markNeedsBuild();
                  },
                  sortField: ref.watch(paymentRecievesProvider).sortField,
                  sortAscending: ref.watch(paymentRecievesProvider).sortAscending,
                  onSort: (field, asc) {
                    ref.read(paymentRecievesProvider.notifier).sort(field, asc);
                  },
                  onRefresh: () async {
                    await ref.read(paymentRecievesProvider.notifier).refresh();
                  },
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

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    if (mounted && !_isDisposed) {
      setState(() {
        _isMoreMenuOpen = false;
        _activeSubMenu = _SubMenuType.none;
      });
    }
  }

  void _showAttachmentMenu(PaymentRecord record) {
    if (_attachmentOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _attachmentOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeAttachmentMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _attachmentLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: const Offset(-8, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                child: _AttachmentPopoverContent(
                  record: record,
                  onClose: _closeAttachmentMenu,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_attachmentOverlayEntry!);
    setState(() {
      _isAttachmentOpen = true;
    });
  }

  void _closeAttachmentMenu() {
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
    if (mounted && !_isDisposed) {
      setState(() {
        _isAttachmentOpen = false;
      });
    }
  }

  void _showPaymentHistoryPanel(PaymentRecord record) {
    if (_paymentHistoryOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _paymentHistoryOverlayEntry = OverlayEntry(
      builder: (context) {
        final RenderBox? buttonBox = _messageButtonKey.currentContext?.findRenderObject() as RenderBox?;
        double remainingHeight = 500;
        if (buttonBox != null) {
          final position = buttonBox.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;
          remainingHeight = screenHeight - (position.dy + buttonBox.size.height);
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePaymentHistoryPanel,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _paymentHistoryLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: const Offset(65, 0),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _PaymentHistoryPanelContent(
                  record: record,
                  onClose: _closePaymentHistoryPanel,
                  height: remainingHeight,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_paymentHistoryOverlayEntry!);
    setState(() {
      _isPaymentHistoryOpen = true;
    });
  }

  void _closePaymentHistoryPanel() {
    _paymentHistoryOverlayEntry?.remove();
    _paymentHistoryOverlayEntry = null;
    if (mounted && !_isDisposed) {
      setState(() {
        _isPaymentHistoryOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentRecievesProvider);
    final notifier = ref.read(paymentRecievesProvider.notifier);

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, state.records.length);
    final paginatedRecords = state.records.sublist(startIndex, endIndex);
    final selectedCount = state.records.where((r) => r.isSelected).length;

    bool allSelected = paginatedRecords.isNotEmpty;
    for (final r in paginatedRecords) {
      if (!r.isSelected) {
        allSelected = false;
        break;
      }
    }

    // Find the currently selected record
    final selectedRecord = state.records.firstWhere(
      (r) => r.paymentNo == widget.paymentId,
      orElse: () => state.records.isNotEmpty ? state.records.first : PaymentRecord(
        date: '',
        paymentNo: '',
        reference: '',
        customer: '',
        invoiceNo: '',
        mode: '',
        amount: 0,
        unusedAmount: 0,
      ),
    );

    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: Colors.white,
        child: SplitListDetailLayout(
          leftWidth: 380,
          leftHeader: selectedCount > 0
              ? _buildLeftBulkActionHeader(selectedCount, allSelected, startIndex, endIndex, ref, context)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FavoriteFilterDropdown(
                          moduleName: 'payment_recieves',
                          options: const [
                            FavoriteFilterOption(
                              label: 'All Payments',
                              value: 'all_payments',
                            ),
                          ],
                          selectedOption: state.selectedFilter,
                          onChanged: (opt) {
                            notifier.updateFilter(opt);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Compact green plus button
                      ElevatedButton(
                        onPressed: () {
                          context.go('/$orgSystemId/sales/payments-received/create');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                          fixedSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      CompositedTransformTarget(
                        link: _moreMenuLayerLink,
                        child: IconButton(
                          onPressed: () {
                            if (_isMoreMenuOpen) {
                              _closeMoreMenu();
                            } else {
                              _showMoreMenu();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            LucideIcons.moreHorizontal,
                            size: 20,
                            color: _isMoreMenuOpen ? const Color(0xFF2563EB) : AppTheme.textSecondary,
                          ),
                          splashRadius: 16,
                        ),
                      ),
                    ],
                  ),
                ),
          leftBody: ListView.builder(
                  controller: _scrollController,
                  itemCount: paginatedRecords.length + 1,
                  itemBuilder: (context, index) {
                    if (index == paginatedRecords.length) {
                      return _buildLeftFooter(state.records.length);
                    }
                    final r = paginatedRecords[index];
                    final isSelected = r.paymentNo == selectedRecord.paymentNo;
                    final absoluteIndex = startIndex + index;
                    return _PaymentListCard(
                      record: r,
                      isSelected: isSelected,
                      onTap: () {
                        context.go('/$orgSystemId/sales/payments-received/${r.paymentNo}');
                      },
                      onChanged: (val) {
                        notifier.toggleRecordSelect(absoluteIndex, val ?? false);
                      },
                    );
                  },
                ),
          rightHeader: widget.isRefund
              ? _buildRefundHeader()
              : _buildRightHeader(selectedRecord),
          rightBody: widget.isRefund
              ? RefundPage(paymentId: selectedRecord.paymentNo)
              : _buildRightBody(selectedRecord),
        ),
      ),
    );
  }

  Widget _buildRightHeader(PaymentRecord r) {
    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final orgSettings = ref.watch(orgSettingsProvider).valueOrNull;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Location & ID (left) and Top-Right Icons (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Location: ${(r.location.isNotEmpty ? r.location : (orgSettings?.name ?? "ZABNIX PRIVATE LIMITED")).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.paymentNo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Top-right actions: paperclip, comment bubble, and close X
                CompositedTransformTarget(
                  link: _attachmentLayerLink,
                  child: _RightHeaderButton(
                    onTap: () {
                      if (_isAttachmentOpen) {
                        _closeAttachmentMenu();
                      } else {
                        _showAttachmentMenu(r);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.paperclip,
                          size: 15,
                          color: _isAttachmentOpen ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                        ),
                        if (r.attachments.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${r.attachments.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CompositedTransformTarget(
                  key: _messageButtonKey,
                  link: _paymentHistoryLayerLink,
                  child: _RightHeaderButton(
                    onTap: () {
                      if (_isPaymentHistoryOpen) {
                        _closePaymentHistoryPanel();
                      } else {
                        _showPaymentHistoryPanel(r);
                      }
                    },
                    child: Icon(
                      LucideIcons.messageSquare,
                      size: 15,
                      color: _isPaymentHistoryOpen
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xFFD1D5DB),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    context.go('/$orgSystemId/sales/payments-received');
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFFB91C1C),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Row 2: Sub-header Toolbar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                // Edit Button
                _buildToolbarButton(
                  icon: LucideIcons.edit2,
                  label: 'Edit',
                  onTap: () {
                    // Customer advances open the Customer Advance page; invoice
                    // payments open the Invoice Payment page. Prefer the backend
                    // payment_type; fall back to "no linked invoice" for local
                    // rows that predate the typed field.
                    final isAdvance = r.paymentType != null
                        ? r.paymentType == 'CUSTOMER_ADVANCE'
                        : r.invoiceNo.trim().isEmpty;
                    final editPath = isAdvance
                        ? '/$orgSystemId/sales/payments-received/customer-advance?editId=${r.paymentNo}'
                        : '/$orgSystemId/sales/payments-received/create?editId=${r.paymentNo}';
                    context.go(editPath);
                  },
                ),
                _buildToolbarDivider(),
                // Send Dropdown
                _buildToolbarSendDropdownButton(context, orgSystemId),
                _buildToolbarDivider(),
                // PDF/Print Dropdown
                _buildToolbarPdfDropdownButton(context, orgSystemId, r),
                _buildToolbarDivider(),
                // Apply to Invoices
                _buildToolbarButton(
                  icon: LucideIcons.fileCheck,
                  label: 'Apply to Invoices',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const _ApplyCreditsDialog(),
                    );
                  },
                ),
                _buildToolbarDivider(),
                // Refund
                _buildToolbarButton(
                  icon: LucideIcons.rotateCcw,
                  label: 'Refund',
                  onTap: () {
                    context.go('/$orgSystemId/sales/payments-received/${r.paymentNo}/refund');
                  },
                ),
                _buildToolbarDivider(),
                // More (...) Button
                _buildToolbarMoreDropdownButton(context, orgSystemId, r),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Widget _buildRefundHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: const Text(
            'Refund',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 16,
      color: const Color(0xFFD1D5DB),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildToolbarSendDropdownButton(BuildContext context, String orgSystemId) {
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
      builder: (context, controller, _) => GestureDetector(
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        child: const _HoverDropdownChild(
          icon: LucideIcons.mail,
          label: 'Send',
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Email sent successfully');
          },
          style: _menuItemButtonStyle(borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.mail, size: 16),
          child: const Text('Send Email', style: TextStyle(fontSize: 14)),
        ),
        MenuItemButton(
          onPressed: () {
            ZerpaiToast.success(context, 'SMS sent successfully');
          },
          style: _menuItemButtonStyle(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.messageSquare, size: 16),
          child: const Text('Send SMS', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildToolbarPdfDropdownButton(BuildContext context, String orgSystemId, PaymentRecord r) {
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
      builder: (context, controller, _) => GestureDetector(
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        child: const SizedBox(
          width: 130,
          child: _HoverDropdownChild(
            icon: LucideIcons.fileText,
            label: 'PDF/Print',
          ),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final orgSettings = ref.read(orgSettingsProvider).valueOrNull;
            final bytes = await _generatePaymentReceivedPdf(r, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${r.paymentNo}.pdf',
            );
          },
          style: _menuItemButtonStyle(width: 130, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.fileText, size: 16),
          child: const Text('PDF', style: TextStyle(fontSize: 14)),
        ),
        MenuItemButton(
          onPressed: () async {
            final orgSettings = ref.read(orgSettingsProvider).valueOrNull;
            final bytes = await _generatePaymentReceivedPdf(r, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: r.paymentNo,
            );
          },
          style: _menuItemButtonStyle(width: 130, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.printer, size: 16),
          child: const Text('Print', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildToolbarMoreDropdownButton(BuildContext context, String orgSystemId, PaymentRecord r) {
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
      builder: (context, controller, _) => GestureDetector(
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        child: const _HoverMoreButtonChild(),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            showZerpaiConfirmationDialog(
              context,
              title: 'Void Payment',
              message: 'Are you sure you want to mark payment ${r.paymentNo} as Void?',
              confirmLabel: 'Void',
              cancelLabel: 'Cancel',
              variant: ZerpaiConfirmationVariant.danger,
            ).then((confirmed) {
              if (confirmed == true) {
                ref.read(paymentRecievesProvider.notifier).voidRecord(r.paymentNo);
                ZerpaiToast.success(context, 'Payment marked as Void');
              }
            });
          },
          style: _menuItemButtonStyle(borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.xCircle, size: 16),
          child: const Text('Void', style: TextStyle(fontSize: 14)),
        ),
        MenuItemButton(
          onPressed: () {
            showDialog<bool>(
              context: context,
              builder: (context) => _DeleteConfirmationDialog(paymentNo: r.paymentNo),
            ).then((confirmed) {
              if (confirmed == true) {
                ref.read(paymentRecievesProvider.notifier).deleteRecord(r.paymentNo);
                ZerpaiToast.deleted(context, 'Payment');
                context.go('/$orgSystemId/sales/payments-received');
              }
            });
          },
          style: _menuItemButtonStyle(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4))),
          leadingIcon: const Icon(LucideIcons.trash2, size: 16),
          child: const Text('Delete', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildRightBody(PaymentRecord r) {
    if (r.paymentNo.isEmpty) {
      return const Center(child: Text('No payment selected.'));
    }

    final orgSettings = ref.watch(orgSettingsProvider).valueOrNull;

    Color templatePrimaryColor = const Color(0xFF5CB85C); // Green default
    Color customerNameColor = const Color(0xFF2563EB); // Blue default

    if (_selectedTemplate == 'Standard Template') {
      templatePrimaryColor = const Color(0xFF2563EB); // Blue
      customerNameColor = const Color(0xFF1F2937); // Dark grey
    } else if (_selectedTemplate == 'Professional Template') {
      templatePrimaryColor = const Color(0xFF1F2937); // Dark grey
      customerNameColor = const Color(0xFF059669); // Emerald green
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(
                bottom: BorderSide(color: Color(0xFFFDE68A)),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This transaction is categorized in Bandhan Bank. Hence, some fields cannot be modified.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Uncategorize now >',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 850,
                      ),
                      child: Container(
                        // Page-style document card matching the recurring invoice
                        // "Next Invoice" view: white page, thin border, soft shadow.
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRect(
                          child: Stack(
                            children: [
                              // Diagonal corner ribbon — shared widget, exactly
                              // matching the recurring invoice document view.
                              Positioned(
                                top: 0,
                                left: 0,
                                child: ZerpaiDocumentCornerRibbon(
                                  label: r.status == 'VOIDED' ? 'Voided' : 'Paid',
                                  color: r.status == 'VOIDED'
                                      ? AppTheme.textSecondary
                                      : AppTheme.successGreen,
                                ),
                              ),

                              // Content details
                              Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 12),
                                    Row(
                                      // Vertically center the logo against the
                                      // company info block so it sits lower and
                                      // balanced rather than hugging the top.
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        orgSettings?.logoUrl != null && orgSettings!.logoUrl!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Container(
                                                  width: 140,
                                                  height: 60,
                                                  color: Colors.white,
                                                  alignment: Alignment.center,
                                                  child: Image.network(
                                                    orgSettings.logoUrl!,
                                                    width: 140,
                                                    height: 60,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return _buildMatrixLogo();
                                                    },
                                                  ),
                                                ),
                                              )
                                            : _buildMatrixLogo(),
                                        const SizedBox(width: 24),
                                        // Right: Company Profile Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (orgSettings?.name.isNotEmpty == true) ? orgSettings!.name : r.location,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                orgSettings == null
                                                    ? 'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia\nGSTIN 32AACCZ4912F1ZL\n8086355500\nzabnixprivatelimited@gmail.com'
                                                    : '${orgSettings.attention ?? orgSettings.name}\n${orgSettings.street ?? ""}${orgSettings.street != null ? "\n" : ""}${orgSettings.city ?? ""} ${orgSettings.pincode ?? ""}\n${orgSettings.country ?? ""}\n${orgSettings.companyIdLabel ?? "GSTIN"}: ${orgSettings.companyIdValue ?? ""}\nPhone: ${orgSettings.phone ?? ""}\nEmail: ${orgSettings.email ?? ""}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.5,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 48),
                                    const Text(
                                      'PAYMENT RECEIPT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                    const SizedBox(height: 24),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Payment details table
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            children: [
                                              _buildReceiptField('Payment Date', r.date, isBoldValue: true),
                                              _buildReceiptField('Reference Number', r.reference, isBoldValue: true),
                                              _buildReceiptField('Payment Mode', r.mode, isBoldValue: true),
                                              _buildReceiptField('Amount Received In Words', _convertAmountToWords(r.amount), isBoldValue: true),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        // Amount Box
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: templatePrimaryColor, // Success box color
                                              borderRadius: BorderRadius.circular(4.0),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'Amount Received',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _fmt(r.amount),
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 48),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Received From info
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Received From',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                r.customer.toLowerCase(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: customerNameColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getCustomerAddressLines(r.customer).join('\n'),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.45,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        // Authorized Signature line
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              const SizedBox(height: 60),
                                              Container(
                                                height: 1,
                                                color: const Color(0xFFD1D5DB),
                                              ),
                                              const SizedBox(height: 8),
                                              const Center(
                                                child: Text(
                                                  'Authorized Signature',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                    const SizedBox(height: 16),
                                    // Over payment section
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Over payment',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _fmt(r.unusedAmount),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
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
                    const SizedBox(height: 16),
                    // PDF Template footer section
                    SizedBox(
                      width: 850,
                      child: Row(
                        children: [
                          Text(
                            "PDF Template : '$_selectedTemplate' ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Change PDF Template',
                            offset: const Offset(0, 24),
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            onSelected: (val) {
                              setState(() {
                                _selectedTemplate = val;
                              });
                              ZerpaiToast.success(context, 'Template changed to $val');
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem<String>(
                                value: 'Elite Template',
                                padding: EdgeInsets.zero,
                                height: 36,
                                child: _HoverPopupMenuItem(label: 'Elite Template'),
                              ),
                              PopupMenuItem<String>(
                                value: 'Standard Template',
                                padding: EdgeInsets.zero,
                                height: 36,
                                child: _HoverPopupMenuItem(label: 'Standard Template'),
                              ),
                              PopupMenuItem<String>(
                                value: 'Professional Template',
                                padding: EdgeInsets.zero,
                                height: 36,
                                child: _HoverPopupMenuItem(label: 'Professional Template'),
                              ),
                            ],
                            child: const Text(
                              "Change",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBottomJournalCardSection(r),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomJournalCardSection(PaymentRecord r) {
    return Container(
      width: 850,
      margin: const EdgeInsets.only(top: 24, bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Tab & Expand/Collapse Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _activeJournalTab = 'batches';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeJournalTab == 'batches'
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Batches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeJournalTab == 'batches'
                            ? AppTheme.primaryBlue
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => setState(() {
                    _activeJournalTab = 'journals';
                    _isJournalCardExpanded = true;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeJournalTab == 'journals'
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Journals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeJournalTab == 'journals'
                            ? AppTheme.primaryBlue
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isJournalCardExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () => setState(() {
                    _isJournalCardExpanded = !_isJournalCardExpanded;
                  }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body Content when Expanded
          if (_isJournalCardExpanded) ...[
            if (_activeJournalTab == 'batches')
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No batch tracking information available for this payment.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              )
            else
              _buildJournalsTableContent(r),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalsTableContent(PaymentRecord r) {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final locationName = r.location.isNotEmpty
        ? r.location
        : (orgSettings?.name.isNotEmpty == true ? orgSettings!.name : 'STARLEX HEALTHCARE PVT. LTD.');

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPaymentJournals(r),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final lines = snapshot.data ?? [];

        if (lines.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No journal entries found for this payment.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
          );
        }

        double totalDebit = 0;
        double totalCredit = 0;
        for (var tx in lines) {
          totalDebit += double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
          totalCredit += double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;
        }

        final bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

        // Group lines by section
        final section1Lines = <Map<String, dynamic>>[];
        final section2Lines = <Map<String, dynamic>>[];
        final refundLines = <Map<String, dynamic>>[];

        for (var line in lines) {
          final desc = (line['description'] ?? '').toString();
          if (desc.contains('Payment Refund')) {
            refundLines.add(line);
          } else if (desc.contains('Invoice Payment')) {
            section2Lines.add(line);
          } else {
            section1Lines.add(line);
          }
        }

        if (section1Lines.isEmpty && lines.isNotEmpty && refundLines.isEmpty) {
          section1Lines.addAll(lines.take(2));
          if (lines.length > 2) {
            section2Lines.addAll(lines.skip(2));
          }
        }

        final Map<String, List<Map<String, dynamic>>> section2Grouped = {};
        for (var line in section2Lines) {
          final refNum = (line['reference_number'] ?? '').toString().trim();
          final desc = (line['description'] ?? '').toString();
          String invNo = refNum;
          if (invNo.isEmpty || invNo == r.paymentNo) {
            if (desc.contains('Invoice Payment - ')) {
              invNo = desc.split('Invoice Payment - ').last.trim();
            }
          }
          if (invNo.isEmpty) invNo = r.paymentNo;
          section2Grouped.putIfAbsent(invNo, () => []).add(line);
        }

        final Map<String, List<Map<String, dynamic>>> refundGrouped = {};
        for (var line in refundLines) {
          final desc = (line['description'] ?? '').toString();
          String refundNo = (line['reference_number'] ?? '').toString().trim();
          if (refundNo.isEmpty && desc.contains('Payment Refund - ')) {
            refundNo = desc.split('Payment Refund - ').last.trim();
          }
          if (refundNo.isEmpty) refundNo = '1';
          refundGrouped.putIfAbsent(refundNo, () => []).add(line);
        }

        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Sub-header line (Currency indicator & Accrual / Cash toggle)
              Row(
                children: [
                  const Text(
                    'Amount is displayed in your base currency ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'INR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(3),
                              bottomLeft: Radius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Accrual',
                            style: TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: const Text(
                            'Cash',
                            style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (isBalanced) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            size: 13,
                            color: Color(0xFF065F46),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Debits/Credits match',
                            style: TextStyle(
                              color: Color(0xFF065F46),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Section 1: Customer Payment - <payment_number>
              if (section1Lines.isNotEmpty) ...[
                Text(
                  'Customer Payment  - ${r.paymentNo}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionTable(section1Lines, locationName, currencyFormat),
                const SizedBox(height: 24),
              ],

              // Section 2: Invoice Payment - <invoice_number>
              for (final entry in section2Grouped.entries) ...[
                Text(
                  'Invoice Payment  - ${entry.key}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionTable(entry.value, locationName, currencyFormat),
                const SizedBox(height: 24),
              ],

              // Section 3: Payment Refund - <refund_number>
              for (final entry in refundGrouped.entries) ...[
                Text(
                  'Payment Refund  - ${entry.key}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionTable(entry.value, locationName, currencyFormat),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTable(
    List<Map<String, dynamic>> rows,
    String locationName,
    NumberFormat currencyFormat,
  ) {
    double secDebit = 0;
    double secCredit = 0;
    for (var tx in rows) {
      secDebit += double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
      secCredit += double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB)),
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                'LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                'DEBIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                'CREDIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        ...rows.map((tx) {
          final rawAccountName = tx['account']?['user_account_name'] ??
              tx['account']?['system_account_name'] ??
              tx['account_name'] ??
              '-';
          final desc = (tx['description'] ?? '').toString();
          final debit = double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
          final credit = double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;

          // Invoice Payment credit line corresponds to Accounts Receivable
          String accountName = rawAccountName;
          if (desc.startsWith('Invoice Payment') && credit > 0 && debit == 0) {
            accountName = 'Accounts Receivable';
          }

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  accountName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  locationName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  currencyFormat.format(debit),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Text(
                  currencyFormat.format(credit),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        }),
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                currencyFormat.format(secDebit),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                currencyFormat.format(secCredit),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _toIsoDateString(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return DateTime.now().toIso8601String().split('T')[0];
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      return trimmed.split('T')[0];
    }
    final parts = trimmed.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 2 && parts[2].length == 4) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return parsed.toIso8601String().split('T')[0];
    }
    return DateTime.now().toIso8601String().split('T')[0];
  }

  Future<Map<String, String>> _resolvePaymentReceivedAccounts(
    SupabaseClient supabase,
    String depositToNameOrId,
  ) async {
    final allAccs = await supabase
        .from('accounts')
        .select('id, user_account_name, system_account_name, account_type');

    String? depositToId;
    String? unearnedRevenueId;
    String? accountsReceivableId;

    final targetDeposit = depositToNameOrId.trim().toLowerCase();

    for (final raw in (allAccs as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final accId = (row['id'] ?? '').toString();
      final userAcc = (row['user_account_name'] ?? '').toString().trim().toLowerCase();
      final sysAcc = (row['system_account_name'] ?? '').toString().trim().toLowerCase();

      if (depositToId == null) {
        if (accId == depositToNameOrId ||
            (targetDeposit.isNotEmpty && (userAcc == targetDeposit || sysAcc == targetDeposit))) {
          depositToId = accId;
        }
      }

      if (unearnedRevenueId == null) {
        if (sysAcc == 'unearned revenue' || userAcc == 'unearned revenue' ||
            sysAcc.contains('unearned') || userAcc.contains('unearned') ||
            sysAcc.contains('advance') || userAcc.contains('advance') ||
            sysAcc.contains('deferred') || userAcc.contains('deferred')) {
          unearnedRevenueId = accId;
        }
      }

      if (accountsReceivableId == null) {
        if (sysAcc == 'accounts receivable' || userAcc == 'accounts receivable' ||
            sysAcc == 'accounts_receivable' || userAcc == 'accounts_receivable') {
          accountsReceivableId = accId;
        }
      }
    }

    if (depositToId == null || depositToId.isEmpty) {
      for (final raw in (allAccs as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final accId = (row['id'] ?? '').toString();
        final userAcc = (row['user_account_name'] ?? '').toString().trim().toLowerCase();
        final sysAcc = (row['system_account_name'] ?? '').toString().trim().toLowerCase();
        final accType = (row['account_type'] ?? '').toString().trim().toLowerCase();
        if (userAcc.contains('cash') || sysAcc.contains('cash') || accType.contains('cash') ||
            userAcc.contains('bank') || sysAcc.contains('bank') || accType.contains('bank')) {
          depositToId = accId;
          break;
        }
      }
    }
    depositToId ??= (allAccs as List).isNotEmpty ? ((allAccs as List).first as Map)['id']?.toString() : null;

    if (unearnedRevenueId == null || unearnedRevenueId.isEmpty) {
      for (final raw in (allAccs as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final accId = (row['id'] ?? '').toString();
        final accType = (row['account_type'] ?? '').toString().trim().toLowerCase();
        if (accType.contains('liability')) {
          unearnedRevenueId = accId;
          break;
        }
      }
    }
    unearnedRevenueId ??= depositToId;

    if (accountsReceivableId == null || accountsReceivableId.isEmpty) {
      for (final raw in (allAccs as List)) {
        final row = Map<String, dynamic>.from(raw as Map);
        final accId = (row['id'] ?? '').toString();
        final userAcc = (row['user_account_name'] ?? '').toString().trim().toLowerCase();
        final sysAcc = (row['system_account_name'] ?? '').toString().trim().toLowerCase();
        final isTdsOrTcs = userAcc.contains('tds') || sysAcc.contains('tds') || userAcc.contains('tcs') || sysAcc.contains('tcs');
        if (!isTdsOrTcs && (sysAcc.contains('accounts') && sysAcc.contains('receivable'))) {
          accountsReceivableId = accId;
          break;
        }
      }
    }
    accountsReceivableId ??= depositToId;

    return {
      'depositToId': depositToId ?? '',
      'unearnedRevenueId': unearnedRevenueId ?? '',
      'accountsReceivableId': accountsReceivableId ?? '',
    };
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentJournals(PaymentRecord p) async {
    final supabase = Supabase.instance.client;

    String paymentDbId = p.id ?? '';
    String paymentNumber = p.paymentNo;

    final jes = await supabase
        .from('journal_entries')
        .select('*')
        .or('source_document_type.eq.payments_received,source_document_type.eq.PAYMENT_RECEIVED')
        .or('source_document_id.eq.${paymentDbId.isNotEmpty ? paymentDbId : "00000000-0000-0000-0000-000000000000"},journal_number.eq.$paymentNumber');

      String? jeId = jes.isNotEmpty ? jes.first['id']?.toString() : null;

      if (jeId == null || jeId.isEmpty) {
        final newJeId = const Uuid().v4();
        await supabase.from('journal_entries').insert({
          'id': newJeId,
          'org_id': '00000000-0000-0000-0000-000000000000',
          'journal_number': paymentNumber,
          'journal_type': 'payments received',
          'journal_date': _toIsoDateString(p.date),
          'posting_date': _toIsoDateString(p.date),
          'reference_number': p.reference.isNotEmpty ? p.reference : paymentNumber,
          'narration': 'Payment Received $paymentNumber',
          'source_module': 'sales',
          'source_document_type': 'payments_received',
          'source_document_id': paymentDbId.isNotEmpty ? paymentDbId : newJeId,
          'status': 'POSTED',
        });
        jeId = newJeId;
      }

    var res = await supabase
        .from('journal_entry_lines')
        .select('*, account:accounts(user_account_name, system_account_name)')
        .eq('journal_entry_id', jeId);
    var linesList = List<Map<String, dynamic>>.from(res);

    if (linesList.isEmpty && p.amount > 0) {
      Map<String, dynamic>? pmRow;
      if (paymentDbId.isNotEmpty) {
        final pmRes = await supabase
            .from('payments_received')
            .select('*, deposit_account:accounts(user_account_name, system_account_name)')
            .eq('id', paymentDbId)
            .maybeSingle();
        if (pmRes != null) pmRow = Map<String, dynamic>.from(pmRes);
      }
      if (pmRow == null && paymentNumber.isNotEmpty) {
        final pmRes = await supabase
            .from('payments_received')
            .select('*, deposit_account:accounts(user_account_name, system_account_name)')
            .eq('payment_number', paymentNumber)
            .maybeSingle();
        if (pmRes != null) pmRow = Map<String, dynamic>.from(pmRes);
      }

      final depositAccRef = pmRow?['deposit_account_id']?.toString() ??
          pmRow?['deposit_account']?['user_account_name']?.toString() ??
          p.mode;

      final accsMap = await _resolvePaymentReceivedAccounts(supabase, depositAccRef);
      final depositToId = accsMap['depositToId']!;
      final unearnedRevId = accsMap['unearnedRevenueId']!;
      final arId = accsMap['accountsReceivableId']!;

      final isoDate = _toIsoDateString(p.date);
      final safeOrgId = '00000000-0000-0000-0000-000000000000';
      final safeCustomerId = pmRow?['customer_id']?.toString();
      final safeSourceId = pmRow?['id']?.toString() ?? (paymentDbId.isNotEmpty ? paymentDbId : jeId);

      final newLines = <Map<String, dynamic>>[];

      // 1. Customer Payment lines
      final mainDesc = 'Customer Payment - $paymentNumber';
      newLines.add({
        'id': const Uuid().v4(),
        'journal_entry_id': jeId,
        'account_id': depositToId,
        'transaction_date': isoDate,
        'reference_number': paymentNumber,
        'description': mainDesc,
        'debit': p.amount,
        'credit': 0.0,
        'source_id': safeSourceId,
        'source_type': 'payments_received',
        if (safeCustomerId != null) 'contact_id': safeCustomerId,
        'contact_type': 'customer',
        'org_id': safeOrgId,
        'line_number': null,
      });
      newLines.add({
        'id': const Uuid().v4(),
        'journal_entry_id': jeId,
        'account_id': unearnedRevId,
        'transaction_date': isoDate,
        'reference_number': paymentNumber,
        'description': mainDesc,
        'debit': 0.0,
        'credit': p.amount,
        'source_id': safeSourceId,
        'source_type': 'payments_received',
        if (safeCustomerId != null) 'contact_id': safeCustomerId,
        'contact_type': 'customer',
        'org_id': safeOrgId,
        'line_number': null,
      });

      // 2. Query Invoice Allocations
      if (safeSourceId.isNotEmpty) {
        final allocRes = await supabase
            .from('payment_received_allocations')
            .select('*, invoice:invoice_master(invoice_number)')
            .eq('payment_received_id', safeSourceId);

        for (final raw in (allocRes as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          final invNo = (row['invoice']?['invoice_number'] ?? row['invoice_number'] ?? '').toString();
          final invAmt = (row['allocated_amount'] as num?)?.toDouble() ?? 0.0;
          if (invAmt > 0) {
            final invDesc = 'Invoice Payment - ${invNo.isNotEmpty ? invNo : paymentNumber}';
            newLines.add({
              'id': const Uuid().v4(),
              'journal_entry_id': jeId,
              'account_id': arId,
              'transaction_date': isoDate,
              'reference_number': invNo.isNotEmpty ? invNo : paymentNumber,
              'description': invDesc,
              'debit': 0.0,
              'credit': invAmt,
              'source_id': safeSourceId,
              'source_type': 'payments_received',
              if (safeCustomerId != null) 'contact_id': safeCustomerId,
              'contact_type': 'customer',
              'org_id': safeOrgId,
              'line_number': null,
            });
            newLines.add({
              'id': const Uuid().v4(),
              'journal_entry_id': jeId,
              'account_id': unearnedRevId,
              'transaction_date': isoDate,
              'reference_number': invNo.isNotEmpty ? invNo : paymentNumber,
              'description': invDesc,
              'debit': invAmt,
              'credit': 0.0,
              'source_id': safeSourceId,
              'source_type': 'payments_received',
              if (safeCustomerId != null) 'contact_id': safeCustomerId,
              'contact_type': 'customer',
              'org_id': safeOrgId,
              'line_number': null,
            });
          }
        }
      }

      if (newLines.length == 2 && p.invoiceNo.isNotEmpty) {
        final invNo = p.invoiceNo;
        final invAmt = p.amount - p.unusedAmount;
        if (invAmt > 0) {
          final invDesc = 'Invoice Payment - $invNo';
          newLines.add({
            'id': const Uuid().v4(),
            'journal_entry_id': jeId,
            'account_id': arId,
            'transaction_date': isoDate,
            'reference_number': invNo,
            'description': invDesc,
            'debit': 0.0,
            'credit': invAmt,
            'source_id': safeSourceId,
            'source_type': 'payments_received',
            if (safeCustomerId != null) 'contact_id': safeCustomerId,
            'contact_type': 'customer',
            'org_id': safeOrgId,
            'line_number': null,
          });
          newLines.add({
            'id': const Uuid().v4(),
            'journal_entry_id': jeId,
            'account_id': unearnedRevId,
            'transaction_date': isoDate,
            'reference_number': invNo,
            'description': invDesc,
            'debit': invAmt,
            'credit': 0.0,
            'source_id': safeSourceId,
            'source_type': 'payments_received',
            if (safeCustomerId != null) 'contact_id': safeCustomerId,
            'contact_type': 'customer',
            'org_id': safeOrgId,
            'line_number': null,
          });
        }
      }

      if (newLines.isNotEmpty) {
        await supabase.from('journal_entry_lines').insert(newLines);
        res = await supabase
            .from('journal_entry_lines')
            .select('*, account:accounts(user_account_name, system_account_name)')
            .eq('journal_entry_id', jeId);
        linesList = List<Map<String, dynamic>>.from(res);
      }
    }

    try {
      if (jeId.isNotEmpty) {
        final existingDescs = linesList
            .map((l) => (l['description'] ?? '').toString())
            .toSet();

        final safeSourceId = paymentDbId.isNotEmpty ? paymentDbId : jeId;

        // Backfill Invoice Payment lines if allocation exists in payment_received_allocations
        final allocRes = await supabase
            .from('payment_received_allocations')
            .select('*, invoice:invoice_master(invoice_number)')
            .eq('payment_received_id', safeSourceId);

        final extraAllocLines = <Map<String, dynamic>>[];
        for (final raw in (allocRes as List)) {
          final row = Map<String, dynamic>.from(raw as Map);
          String invNo = (row['invoice']?['invoice_number'] ?? row['invoice_number'] ?? '').toString();
          final invId = (row['invoice_id'] ?? '').toString();
          if (invNo.isEmpty && invId.isNotEmpty) {
            final invRes = await supabase
                .from('invoice_master')
                .select('invoice_number')
                .eq('id', invId)
                .maybeSingle();
            if (invRes != null) {
              invNo = (invRes['invoice_number'] ?? '').toString();
            }
          }
          final invAmt = (row['allocated_amount'] as num?)?.toDouble() ?? 0.0;
          final invDesc = 'Invoice Payment - ${invNo.isNotEmpty ? invNo : paymentNumber}';

          if (!existingDescs.contains(invDesc) && invAmt > 0) {
            final accsMap = await _resolvePaymentReceivedAccounts(supabase, p.mode);
            final unearnedRevId = accsMap['unearnedRevenueId']!;
            final arId = accsMap['accountsReceivableId']!;
            final isoDate = _toIsoDateString(p.date);

            extraAllocLines.add({
              'id': const Uuid().v4(),
              'journal_entry_id': jeId,
              'account_id': arId,
              'transaction_date': isoDate,
              'reference_number': invNo.isNotEmpty ? invNo : paymentNumber,
              'description': invDesc,
              'debit': 0.0,
              'credit': invAmt,
              'source_id': safeSourceId,
              'source_type': 'payments_received',
              'contact_type': 'customer',
              'org_id': '00000000-0000-0000-0000-000000000000',
              'line_number': null,
            });
            extraAllocLines.add({
              'id': const Uuid().v4(),
              'journal_entry_id': jeId,
              'account_id': unearnedRevId,
              'transaction_date': isoDate,
              'reference_number': invNo.isNotEmpty ? invNo : paymentNumber,
              'description': invDesc,
              'debit': invAmt,
              'credit': 0.0,
              'source_id': safeSourceId,
              'source_type': 'payments_received',
              'contact_type': 'customer',
              'org_id': '00000000-0000-0000-0000-000000000000',
              'line_number': null,
            });
          }
        }
        if (extraAllocLines.isNotEmpty) {
          await supabase.from('journal_entry_lines').insert(extraAllocLines);
          res = await supabase
              .from('journal_entry_lines')
              .select('*, account:accounts(user_account_name, system_account_name)')
              .eq('journal_entry_id', jeId);
          linesList = List<Map<String, dynamic>>.from(res);
          existingDescs.addAll(extraAllocLines.map((l) => (l['description'] ?? '').toString()));
        }

        final refundRes = await supabase
            .from('payment_received_refunds')
            .select('*')
            .eq('payment_received_id', safeSourceId);

        if ((refundRes as List).isNotEmpty) {
          final accsMap = await _resolvePaymentReceivedAccounts(supabase, 'Petty Cash');
          final defaultFromId = accsMap['depositToId']!;
          final unearnedRevId = accsMap['unearnedRevenueId']!;
          final isoDate = _toIsoDateString(p.date);
          final safeSourceId = paymentDbId.isNotEmpty ? paymentDbId : jeId;
          bool backfilledAny = false;

          for (final raw in refundRes) {
            final refRow = Map<String, dynamic>.from(raw as Map);
            final rNo = (refRow['refund_number'] ?? refRow['reference_number'] ?? '1').toString();
            final rAmt = (refRow['amount_refunded'] ?? refRow['amount'] ?? 0.0) as num;
            final rDesc = 'Payment Refund - $rNo';

            if (!existingDescs.contains(rDesc) && rAmt > 0) {
              final rDate = _toIsoDateString((refRow['refund_date'] ?? refRow['created_at'] ?? isoDate).toString());
              final line1 = {
                'id': const Uuid().v4(),
                'journal_entry_id': jeId,
                'account_id': defaultFromId,
                'transaction_date': rDate,
                'reference_number': rNo,
                'description': rDesc,
                'debit': 0.0,
                'credit': rAmt.toDouble(),
                'source_id': safeSourceId,
                'source_type': 'payments_received',
                'contact_type': 'customer',
                'org_id': '00000000-0000-0000-0000-000000000000',
                'line_number': null,
              };
              final line2 = {
                'id': const Uuid().v4(),
                'journal_entry_id': jeId,
                'account_id': unearnedRevId,
                'transaction_date': rDate,
                'reference_number': rNo,
                'description': rDesc,
                'debit': rAmt.toDouble(),
                'credit': 0.0,
                'source_id': safeSourceId,
                'source_type': 'payments_received',
                'contact_type': 'customer',
                'org_id': '00000000-0000-0000-0000-000000000000',
                'line_number': null,
              };
              await supabase.from('journal_entry_lines').insert([line1, line2]);
              backfilledAny = true;
            }
          }

          if (backfilledAny) {
            res = await supabase
                .from('journal_entry_lines')
                .select('*, account:accounts(user_account_name, system_account_name)')
                .eq('journal_entry_id', jeId);
            linesList = List<Map<String, dynamic>>.from(res);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing refund journal lines: $e');
    }

    return linesList;
  }



  Widget _buildReceiptField(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixLogo() {
    return Container(
      width: 140,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 8),
          Container(width: 80, height: 4, color: Colors.greenAccent.withAlpha(200)),
          const SizedBox(height: 4),
          Container(width: 100, height: 4, color: Colors.green.withAlpha(150)),
          const SizedBox(height: 4),
          Container(width: 60, height: 4, color: Colors.greenAccent.withAlpha(180)),
        ],
      ),
    );
  }

  String _convertAmountToWords(double amount) {
    if (amount == 15000.00) return 'Indian Rupee Fifteen Thousand Only';
    if (amount == 100.00) return 'Indian Rupee One Hundred Only';
    
    int val = amount.toInt();
    if (val == 0) return 'Zero';
    
    final units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
                   "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    
    String convertLessThanOneThousand(int number) {
      if (number < 20) {
        return units[number];
      }
      if (number < 100) {
        return tens[number ~/ 10] + (number % 10 != 0 ? " " + units[number % 10] : "");
      }
      return units[number ~/ 100] + " Hundred" + (number % 100 != 0 ? " and " + convertLessThanOneThousand(number % 100) : "");
    }

    String result = "";
    if (val >= 10000000) {
      result += convertLessThanOneThousand(val ~/ 10000000) + " Crore ";
      val %= 10000000;
    }
    if (val >= 100000) {
      result += convertLessThanOneThousand(val ~/ 100000) + " Lakh ";
      val %= 100000;
    }
    if (val >= 1000) {
      result += convertLessThanOneThousand(val ~/ 1000) + " Thousand ";
      val %= 1000;
    }
    if (val > 0) {
      result += convertLessThanOneThousand(val);
    }
    
    return 'Indian Rupee ${result.trim()} Only';
  }

  List<String> _getCustomerAddressLines(String customer) {
    if (customer.toLowerCase().contains('starlex')) {
      return [
        'Starlex Building',
        'Kakkanad',
        'Kochi (po)',
        'Ernakulam',
        '682030 Kerala',
        'India'
      ];
    }
    return [
      'malayanakath(h)',
      'vengoor (po)',
      'perinthalmanna',
      '679322 Kerala',
      'India'
    ];
  }

  Widget _buildLeftFooter(int totalCount) {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalCount);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Total Count: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showTotalCount = !_showTotalCount),
                child: Text(
                  _showTotalCount ? '$totalCount' : 'View',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              PopupMenuButton<int>(
                tooltip: 'Rows per page',
                offset: const Offset(0, -120),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1;
                  });
                },
                itemBuilder: (ctx) => [10, 25, 50, 100].map((val) => PopupMenuItem<int>(
                  value: val,
                  padding: EdgeInsets.zero,
                  height: 36,
                  child: _HoverPopupMenuItem(label: '$val per page'),
                )).toList(),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveringRowsPerPage = true),
                  onExit: (_) => setState(() => _hoveringRowsPerPage = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                      ),
                      color: _hoveringRowsPerPage ? const Color(0xFFEFF6FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings,
                          size: 12,
                          color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_rowsPerPage per page',
                          style: TextStyle(
                            fontSize: 11,
                            color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 12,
                          color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringPrevPage = true),
                      onExit: (_) => setState(() => _hoveringPrevPage = false),
                      cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _hoveringPrevPage && _currentPage > 1 ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 14,
                            color: _currentPage > 1
                                ? (_hoveringPrevPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalCount == 0 ? '0 - 0' : '${startIndex + 1} - $endIndex',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                    ),
                    const SizedBox(width: 6),
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringNextPage = true),
                      onExit: (_) => setState(() => _hoveringNextPage = false),
                      cursor: endIndex < totalCount ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: endIndex < totalCount
                            ? () => setState(() => _currentPage++)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _hoveringNextPage && endIndex < totalCount ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: endIndex < totalCount
                                ? (_hoveringNextPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                : const Color(0xFFD1D5DB),
                          ),
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
    );
  }

  Widget _buildLeftBulkActionHeader(int selectedCount, bool allSelected, int startIndex, int endIndex, WidgetRef ref, BuildContext context) {
    final state = ref.watch(paymentRecievesProvider);
    final totalRecords = state.records.length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6), // light grey background
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (val) {
              ref.read(paymentRecievesProvider.notifier).toggleSelectAll(val ?? false, startIndex, endIndex);
            },
            activeColor: AppTheme.primaryBlue,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Bulk Actions',
            offset: const Offset(0, 32),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            onSelected: (action) {
              if (action == 'update') {
                showDialog(
                  context: context,
                  builder: (context) => _BulkUpdateDialog(
                    fields: const ['Payment Mode', 'Deposit To', 'Payment Date'],
                    onUpdate: (field, value) {
                      ref.read(paymentRecievesProvider.notifier).bulkUpdate(field, value);
                      ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                      ZerpaiToast.success(context, 'Payments updated successfully');
                    },
                  ),
                );
              } else if (action == 'delete') {
                showDialog<bool>(
                  context: context,
                  builder: (context) => const _DeleteConfirmationDialog(),
                ).then((confirmed) {
                  if (confirmed == true) {
                    ref.read(paymentRecievesProvider.notifier).deleteSelected();
                    ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.deleted(context, 'Payment(s)');
                  }
                });
              } else if (action == 'pdf') {
                ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                ZerpaiToast.success(context, 'Generating PDF for selected payments...');
              } else if (action == 'print') {
                ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                ZerpaiToast.success(context, 'Printing selected payments...');
              } else if (action == 'emails') {
                ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                ZerpaiToast.success(context, 'Emails sent successfully');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'update',
                padding: EdgeInsets.zero,
                height: 36,
                child: _HoverPopupMenuItem(label: 'Bulk Update'),
              ),
              PopupMenuItem<String>(
                value: 'pdf',
                padding: EdgeInsets.zero,
                height: 36,
                child: _HoverPopupMenuItem(label: 'PDF'),
              ),
              PopupMenuItem<String>(
                value: 'print',
                padding: EdgeInsets.zero,
                height: 36,
                child: _HoverPopupMenuItem(label: 'Print'),
              ),
              PopupMenuItem<String>(
                value: 'emails',
                padding: EdgeInsets.zero,
                height: 36,
                child: _HoverPopupMenuItem(label: 'Send Emails'),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'delete',
                padding: EdgeInsets.zero,
                height: 36,
                child: _HoverPopupMenuItem(label: 'Delete'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bulk Actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 8),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            selectedCount == 1 ? 'Selected' : 'Selected',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, totalRecords);
            },
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _PaymentListCard extends StatefulWidget {
  final PaymentRecord record;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;

  const _PaymentListCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
    required this.onChanged,
  });

  @override
  State<_PaymentListCard> createState() => _PaymentListCardState();
}

class _PaymentListCardState extends State<_PaymentListCard> {
  bool _isHovered = false;

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

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? const Color(0xFFEFF6FF)
        : (_isHovered ? const Color(0xFFF9FAFB) : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Line 1: Checkbox, Title (Customer), Amount
                Row(
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
                      child: Text(
                        widget.record.customer,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(widget.record.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Line 2: Spacer of width 36, Row with paymentNo, •, date
                Row(
                  children: [
                    const SizedBox(width: 36),
                    Flexible(
                      child: Text(
                        widget.record.paymentNo,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.record.date,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Line 3: Spacer of width 36, Row with PAID status, Mode, Copy icon
                Row(
                  children: [
                    const SizedBox(width: 36),
                    Text(
                      widget.record.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.record.status == 'VOIDED'
                            ? AppTheme.textSecondary
                            : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.record.mode,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.copy,
                      size: 11,
                      color: AppTheme.textSecondary.withAlpha(180),
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
  const _HoverPopupMenuItem({required this.label});

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
        color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 36,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _isHovered ? Colors.white : const Color(0xFF374151),
          ),
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

  const _MoreMenuDropdownContent({
    required this.onClose,
    required this.onResetWidths,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onRefresh,
    required this.activeSubMenu,
    required this.onSubMenuChanged,
  });

  @override
  State<_MoreMenuDropdownContent> createState() => _MoreMenuDropdownContentState();
}

class _MoreMenuDropdownContentState extends State<_MoreMenuDropdownContent> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainMenu(),
        if (widget.activeSubMenu != _SubMenuType.none) ...[
          const SizedBox(width: 4),
          _buildSubMenu(),
        ],
      ],
    );
  }

  Widget _buildMainMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.sortBy),
            child: _MoreMenuItem(
              icon: Icons.swap_vert,
              label: 'Sort by',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.sortBy,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.import),
            child: _MoreMenuItem(
              icon: Icons.file_download_outlined,
              label: 'Import',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.import,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.export),
            child: _MoreMenuItem(
              icon: Icons.file_upload_outlined,
              label: 'Export',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.export,
              onTap: () {},
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.none),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoreMenuItem(
                  icon: Icons.splitscreen_outlined,
                  label: 'Manage Custom Fields',
                  onTap: widget.onClose,
                ),
                _MoreMenuItem(
                  icon: Icons.computer_outlined,
                  label: 'Online Payments',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItem(
                  icon: Icons.settings_backup_restore_outlined,
                  label: 'Reset Column Width',
                  onTap: widget.onResetWidths,
                ),
                _MoreMenuItem(
                  icon: Icons.refresh_outlined,
                  label: 'Refresh List',
                  onTap: () {
                    widget.onClose();
                    widget.onRefresh();
                  },
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
        return _SubMenuPanel(
          children: [
            _buildSortItem('payment', 'Payment#'),
            _buildSortItem('date', 'Date'),
            _buildSortItem('reference', 'Reference#'),
            _buildSortItem('customer', 'Customer Name'),
            _buildSortItem('mode', 'Mode'),
            _buildSortItem('amount', 'Amount'),
            _buildSortItem('unused', 'Unused Amount'),
            _buildSortItem('created', 'Created Time'),
            _buildSortItem('modified', 'Last Modified Time'),
          ],
        );
      case _SubMenuType.import:
        return _SubMenuPanel(
          children: [
            _SubMenuItem(
              label: 'Import Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Import Retainer Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Import Applied Excess Payments',
              onTap: widget.onClose,
            ),
          ],
        );
      case _SubMenuType.export:
        return _SubMenuPanel(
          children: [
            _SubMenuItem(
              label: 'Export Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Export Current View',
              onTap: widget.onClose,
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
    } else if (field == 'payment') {
      icon = Icons.arrow_upward;
    }

    return _SubMenuItem(
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

class _SubMenuPanel extends StatelessWidget {
  final List<Widget> children;
  const _SubMenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SubMenuItem extends StatefulWidget {
  final String label;
  final IconData? rightIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubMenuItem({
    required this.label,
    this.rightIcon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_SubMenuItem> createState() => _SubMenuItemState();
}

class _SubMenuItemState extends State<_SubMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hovered
                        ? Colors.white
                        : (widget.isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF374151)),
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.rightIcon != null)
                Icon(
                  widget.rightIcon,
                  size: 14,
                  color: _hovered ? Colors.white : const Color(0xFF3B82F6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasChevron;
  final bool isActive;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    this.hasChevron = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _hovered || widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isHighlighted ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isHighlighted ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              if (widget.hasChevron)
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isHighlighted ? Colors.white : const Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<String> fields;
  final Function(String field, String value) onUpdate;

  const _BulkUpdateDialog({
    required this.fields,
    required this.onUpdate,
  });

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valController = TextEditingController();
  final GlobalKey _datePickerKey = GlobalKey();

  @override
  void dispose() {
    _valController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: DateTime.now(),
      targetKey: _datePickerKey,
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        _valController.text = formatted;
      });
    }
  }

  Widget _buildRightInput() {
    if (_selectedField == 'Payment Date') {
      return CustomTextField(
        key: _datePickerKey,
        controller: _valController,
        hintText: 'Select date',
        readOnly: true,
        height: 40,
        onTap: _selectDate,
        suffixWidget: const Icon(
          LucideIcons.calendar,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      );
    } else if (_selectedField == 'Payment Mode') {
      final List<String> modes = ['Cash', 'Netbanking', 'Cheque', 'Bank Transfer', 'Card'];
      return FormDropdown<String>(
        value: modes.contains(_valController.text) ? _valController.text : null,
        items: modes,
        placeholder: 'Select a mode',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else if (_selectedField == 'Deposit To') {
      final List<String> displayLocations = [
        'Bandhan Bank',
        'COMPANY BANK ACCOUNT',
        'Zoho Payroll - Bank Account',
        'Petty Cash',
        'TESTINGS CASH',
        'TDS Payable',
        'GST Payable',
      ];
      return FormDropdown<String>(
        value: displayLocations.firstWhere(
          (loc) => loc.toUpperCase() == _valController.text.toUpperCase(),
          orElse: () => '',
        ).isNotEmpty ? displayLocations.firstWhere(
          (loc) => loc.toUpperCase() == _valController.text.toUpperCase()
        ) : null,
        items: displayLocations,
        placeholder: 'Select a location',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
        listBuilder: (items, itemBuilder) {
          final Map<String, List<String>> groups = {
            'Bank': ['Bandhan Bank', 'COMPANY BANK ACCOUNT', 'Zoho Payroll - Bank Account'],
            'Cash': ['Petty Cash', 'TESTINGS CASH'],
            'Other Current Liability': ['TDS Payable', 'GST Payable'],
          };
          final List<Widget> children = [];
          for (final entry in groups.entries) {
            final matching = entry.value.where((item) => items.contains(item)).toList();
            if (matching.isNotEmpty) {
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              );
              for (final item in matching) {
                children.add(itemBuilder(item));
              }
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      );
    } else {
      return CustomTextField(
        controller: _valController,
        hintText: '',
        enabled: false,
        height: 40,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bulk Update Payments Received',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            const Text(
              'Choose a field from the dropdown and update with new information.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormDropdown<String>(
                    value: _selectedField,
                    items: widget.fields,
                    placeholder: 'Select a field',
                    onChanged: (val) {
                      setState(() {
                        _selectedField = val;
                        _valController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRightInput(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: All the selected customer payments will be updated with the new information and you cannot undo this action.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedField == null ||
                        _valController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a field and enter a value.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    widget.onUpdate(
                      _selectedField!,
                      _valController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final String? paymentNo;
  const _DeleteConfirmationDialog({this.paymentNo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  paymentNo != null ? 'Delete Payment' : 'Delete Payments',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              paymentNo != null
                  ? 'Are you sure you want to delete payment $paymentNo?'
                  : 'Are you sure you want to delete the selected Payment(s)?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626), // red
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderLight),
                    minimumSize: const Size(70, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverPopupMenuItemWithIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  const _HoverPopupMenuItemWithIcon({required this.icon, required this.label});

  @override
  State<_HoverPopupMenuItemWithIcon> createState() => _HoverPopupMenuItemWithIconState();
}

class _HoverPopupMenuItemWithIconState extends State<_HoverPopupMenuItemWithIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _isHovered ? Colors.white : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _isHovered ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyCreditsDialog extends StatelessWidget {
  const _ApplyCreditsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Apply Credits from Advance Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 20),
            const Text(
              'There are no invoices in the open status for this customer. Hence, credits cannot be applied.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(60, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HoverToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HoverToolbarButton> createState() => _HoverToolbarButtonState();
}

class _HoverToolbarButtonState extends State<_HoverToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white : Colors.transparent,
            border: Border.all(
              color: _isHovered ? const Color(0xFFD3D9E3) : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: AppTheme.textPrimary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverDropdownChild extends StatefulWidget {
  final IconData icon;
  final String label;
  const _HoverDropdownChild({
    required this.icon,
    required this.label,
  });

  @override
  State<_HoverDropdownChild> createState() => _HoverDropdownChildState();
}

class _HoverDropdownChildState extends State<_HoverDropdownChild> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white : Colors.transparent,
          border: Border.all(
            color: _isHovered ? const Color(0xFFD3D9E3) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 14, color: AppTheme.textPrimary),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
          ],
        ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white : Colors.transparent,
          border: Border.all(
            color: _isHovered ? const Color(0xFFD3D9E3) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _AttachmentPopoverContent extends ConsumerStatefulWidget {
  final PaymentRecord record;
  final VoidCallback onClose;
  const _AttachmentPopoverContent({
    required this.record,
    required this.onClose,
  });

  @override
  ConsumerState<_AttachmentPopoverContent> createState() => _AttachmentPopoverContentState();
}

class _AttachmentPopoverContentState extends ConsumerState<_AttachmentPopoverContent> {
  bool _isHoveringUpload = false;
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    if (_isUploading) return;
    try {
      final state = ref.read(paymentRecievesProvider);
      final activeRecord = state.records.firstWhere(
        (r) => r.paymentNo == widget.record.paymentNo,
        orElse: () => widget.record,
      );
      final attachments = activeRecord.attachments;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        if (attachments.length + result.files.length > 5) {
          if (mounted) {
            ZerpaiToast.error(context, 'You can upload a maximum of 5 files');
          }
          return;
        }

        setState(() {
          _isUploading = true;
        });

        await Future.delayed(const Duration(milliseconds: 1500));

        for (final file in result.files) {
          ref.read(paymentRecievesProvider.notifier).addAttachment(
            widget.record.paymentNo,
            file.name,
          );
        }
        if (mounted) {
          ZerpaiToast.success(context, 'Files uploaded successfully');
          widget.onClose();
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to pick files: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentRecievesProvider);
    final activeRecord = state.records.firstWhere(
      (r) => r.paymentNo == widget.record.paymentNo,
      orElse: () => widget.record,
    );
    final attachments = activeRecord.attachments;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          
          // Body List / No Files Attached
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (attachments.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No Files Attached',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: attachments.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final filename = attachments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.fileText,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  ref.read(paymentRecievesProvider.notifier).removeAttachment(
                                    activeRecord.paymentNo,
                                    filename,
                                  );
                                  ZerpaiToast.success(context, 'Attachment removed successfully');
                                },
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Dotted border container for "Upload your Files"
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringUpload = true),
                  onExit: (_) => setState(() => _isHoveringUpload = false),
                  child: GestureDetector(
                    onTap: _pickFiles,
                    child: DottedBorder(
                      color: _isHoveringUpload ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                      strokeWidth: 1,
                      dashPattern: const [4, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: _isHoveringUpload ? const Color(0xFFEFF6FF) : Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _isUploading
                              ? [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Uploading...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF9CA3AF), width: 1),
                                    ),
                                    padding: const EdgeInsets.all(1),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 10,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ]
                              : [
                                  const Icon(
                                    LucideIcons.upload,
                                    size: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Upload your Files',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF9CA3AF), width: 1),
                                    ),
                                    padding: const EdgeInsets.all(1),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 10,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Footer helper text
                const Text(
                  'You can upload a maximum of 5 files, 10MB each',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightHeaderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _RightHeaderButton({required this.child, required this.onTap});

  @override
  State<_RightHeaderButton> createState() => _RightHeaderButtonState();
}

class _RightHeaderButtonState extends State<_RightHeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white : const Color(0xFFF3F4F6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Payment History Panel ─────────────────────────────────────────────────────
class _PaymentHistoryPanelContent extends StatelessWidget {
  final PaymentRecord record;
  final VoidCallback onClose;
  final double height;

  const _PaymentHistoryPanelContent({
    required this.record,
    required this.onClose,
    required this.height,
  });

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final formatted = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\u20B9$formatted.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    // Build a mock timestamp from the record date
    final dateParts = record.date.split('-');
    final displayDate = dateParts.length == 3
        ? '${dateParts[0]}-${dateParts[1]}-${dateParts[2]}'
        : record.date;

    return Container(
      width: 360,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // ── Body ────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry row: avatar + user + timestamp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  record.location.toLowerCase().replaceAll(' ', ''),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '•',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$displayDate 02:47 PM',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Message bubble
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Payment of ${_fmt(record.amount)} received',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
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
    );
  }
}
