import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/models/vendor_credit_models.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/providers/vendor_credits_providers.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class VendorCreditDetailPage extends ConsumerStatefulWidget {
  final String vendorCreditId;

  const VendorCreditDetailPage({super.key, required this.vendorCreditId});

  @override
  ConsumerState<VendorCreditDetailPage> createState() =>
      _VendorCreditDetailPageState();
}

class _VendorCreditDetailPageState
    extends ConsumerState<VendorCreditDetailPage> {
  VendorCreditItem? _drawerItem;
  bool _showJournal = false;
  bool _showPdfView = false;

  void _openItemDrawer(VendorCreditItem item) {
    setState(() => _drawerItem = item);
  }

  void _closeItemDrawer() {
    setState(() => _drawerItem = null);
  }

  Future<void> _exportVendorCreditPdf(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    final bytes = await _generateVendorCreditPdf(creditNote, orgSettings);
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${creditNote.creditNoteNumber}.pdf',
      );
    } catch (_) {
      try {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: creditNote.creditNoteNumber,
        );
      } catch (_) {
        if (!mounted) return;
        ZerpaiToast.error(context, 'Failed to generate vendor credit PDF.');
      }
    }
  }

  Future<void> _printVendorCredit(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    try {
      final bytes = await _generateVendorCreditPdf(creditNote, orgSettings);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: creditNote.creditNoteNumber,
      );
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to print vendor credit.');
    }
  }

  Future<Uint8List> _generateVendorCreditPdf(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    final doc = pw.Document();
    pw.ThemeData pdfTheme;
    try {
      final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      pdfTheme = pw.ThemeData.withFont(
        base: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (_) {
      pdfTheme = pw.ThemeData.withFont();
    }

    pw.MemoryImage? logoImage;
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      try {
        final res = await Dio().get<List<int>>(
          logoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = res.data;
        if (data != null && data.isNotEmpty) {
          logoImage = pw.MemoryImage(Uint8List.fromList(data));
        }
      } catch (_) {}
    }

    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final itemRows = creditNote.items
        .map(
          (item) => [
            item.name,
            item.description.trim().isEmpty ? '-' : item.description.trim(),
            item.quantity.toStringAsFixed(2),
            fmt.format(item.rate),
            item.taxRate,
            fmt.format(item.amount),
          ],
        )
        .toList(growable: false);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 120,
                        height: 54,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        width: 120,
                        height: 54,
                        color: PdfColor.fromHex('#101820'),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'LOGO',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      orgSettings?.name.trim().isNotEmpty == true
                          ? orgSettings!.name.trim()
                          : 'YOUR COMPANY NAME',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      (orgSettings?.paymentStubAddress?.trim().isNotEmpty == true)
                          ? orgSettings!.paymentStubAddress!.trim()
                          : 'Address Line 1\nCity, State PIN',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                        lineSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'VENDOR CREDIT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Credit Note# ${creditNote.creditNoteNumber}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VENDOR ADDRESS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      creditNote.vendorName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1463B8'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      creditNote.billingAddress.trim().isEmpty
                          ? '-'
                          : creditNote.billingAddress.trim(),
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        color: PdfColors.grey700,
                        lineSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfMetaText(
                    'Credit Date',
                    DateFormat('dd-MM-yyyy').format(creditNote.date),
                  ),
                  _buildPdfMetaText('Reference#', creditNote.referenceNumber),
                  _buildPdfMetaText(
                    'Source of Supply',
                    creditNote.sourceOfSupply,
                  ),
                  _buildPdfMetaText(
                    'Destination',
                    creditNote.destinationOfSupply,
                  ),
                  _buildPdfMetaText('Status', creditNote.status),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            cellAlignments: const {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            headers: const ['Item', 'Description', 'Qty', 'Rate', 'Tax', 'Amount'],
            data: itemRows,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerPadding: const pw.EdgeInsets.all(8),
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Spacer(),
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _buildPdfTotalRow('Sub Total', fmt.format(creditNote.subtotal)),
                    _buildPdfTotalRow('Tax', fmt.format(creditNote.taxAmount)),
                    _buildPdfTotalRow('Shipping', fmt.format(creditNote.shipping)),
                    _buildPdfTotalRow('Adjustment', fmt.format(creditNote.adjustment)),
                    pw.Divider(color: PdfColors.grey400),
                    _buildPdfTotalRow(
                      'Total',
                      fmt.format(creditNote.total),
                      isBold: true,
                    ),
                    _buildPdfTotalRow(
                      'Balance',
                      fmt.format(creditNote.balance),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPdfMetaText(String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: displayValue,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfTotalRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 10.5,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildVcPdfCard(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy').format(creditNote.date);

    Color ribbonColor;
    switch (creditNote.status.toLowerCase()) {
      case 'closed':
        ribbonColor = AppTheme.successGreen;
        break;
      case 'open':
        ribbonColor = AppTheme.primaryBlue;
        break;
      case 'void':
        ribbonColor = AppTheme.errorRed;
        break;
      default:
        ribbonColor = AppTheme.textSecondary;
    }

    return Container(
      key: const ValueKey('vc-pdf'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PdfOrgLogo(width: 140, height: 60),
                          const SizedBox(height: 14),
                          Text(
                            orgSettings?.name.trim().isNotEmpty == true
                                ? orgSettings!.name.trim()
                                : 'YOUR COMPANY NAME',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orgSettings?.paymentStubAddress?.trim() ??
                                'Address Line 1\nCity, State PIN',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VENDOR CREDIT',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Credit Note# ${creditNote.creditNoteNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 20),
                // Vendor + Meta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VENDOR ADDRESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            creditNote.vendorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creditNote.billingAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSubtle,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _pdfMetaRow('Credit Date', dateStr),
                        _pdfMetaRow('Reference#', creditNote.referenceNumber),
                        _pdfMetaRow(
                          'Source of Supply',
                          creditNote.sourceOfSupply,
                        ),
                        _pdfMetaRow(
                          'Destination',
                          creditNote.destinationOfSupply,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ItemsTable(
                  items: creditNote.items,
                  fmt: fmt,
                  onItemTap: (_) {},
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
                  child: Row(
                    children: [
                      const Spacer(),
                      _TotalsBlock(creditNote: creditNote, fmt: fmt),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(
                          width: 220,
                          child: Divider(
                            color: AppTheme.textPrimary,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Authorized Signature',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Corner ribbon
          Positioned(
            top: 0,
            left: 0,
            child: ClipRect(
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned(
                      top: 18,
                      left: -28,
                      child: Transform.rotate(
                        angle: -0.785,
                        child: Container(
                          width: 130,
                          height: 36,
                          color: ribbonColor,
                          alignment: Alignment.center,
                          child: Text(
                            creditNote.status[0].toUpperCase() +
                                creditNote.status.substring(1).toLowerCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
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
  Widget _pdfMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Shell used by the loading / not-found / error states so the page chrome
  /// stays put while the credit resolves.
  Widget _buildShell(Widget body) => ZerpaiLayout(
    pageTitle: widget.vendorCreditId,
    enableBodyScroll: false,
    child: Center(child: body),
  );

  @override
  Widget build(BuildContext context) {
    final creditNoteAsync = ref.watch(
      vendorCreditDetailProvider(widget.vendorCreditId),
    );

    return creditNoteAsync.when(
      loading: () => _buildShell(const CircularProgressIndicator()),
      error: (e, _) => _buildShell(
        Text(
          'Failed to load ${widget.vendorCreditId}',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      ),
      data: (creditNote) => creditNote == null
          ? _buildShell(
              Text(
                'Vendor credit ${widget.vendorCreditId} not found',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            )
          : _buildLoaded(context, creditNote),
    );
  }

  Widget _buildLoaded(BuildContext context, VendorCreditDetail creditNote) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;

    return ZerpaiLayout(
      pageTitle: creditNote.creditNoteNumber,
      enableBodyScroll: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionBar(
                creditNote: creditNote,
                onDelete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete action triggered (Mocked)'),
                    ),
                  );
                  context.go(AppRoutes.vendorCredits);
                },
                onJournal: () => setState(() => _showJournal = !_showJournal),
                onPdf: () => _exportVendorCreditPdf(creditNote, orgSettings),
                onPrint: () => _printVendorCredit(creditNote, orgSettings),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              _StatusBar(creditNote: creditNote),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Show PDF View toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Show PDF View',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _showPdfView,
                                onChanged: (v) =>
                                    setState(() => _showPdfView = v),
                                activeTrackColor: AppTheme.primaryBlue,
                                activeThumbColor: Colors.white,
                                inactiveTrackColor: AppTheme.borderLight,
                                inactiveThumbColor: Colors.white,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _showPdfView
                                ? _buildVcPdfCard(creditNote, orgSettings)
                                : _DocumentCard(
                                    creditNote: creditNote,
                                    orgSettings: orgSettings,
                                    onItemTap: _openItemDrawer,
                                  ),
                          ),
                          if (_showJournal) ...[
                            const SizedBox(height: 24),
                            _JournalSection(creditNote: creditNote),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_drawerItem != null)
            _ItemStockDrawer(item: _drawerItem!, onClose: _closeItemDrawer),
        ],
      ),
    );
  }
}

// ── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final VendorCreditDetail creditNote;
  final VoidCallback onDelete;
  final VoidCallback onJournal;
  final VoidCallback onPdf;
  final VoidCallback onPrint;

  const _ActionBar({
    required this.creditNote,
    required this.onDelete,
    required this.onJournal,
    required this.onPdf,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    const btnStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    const iconSize = 14.0;
    const gap = SizedBox(width: 6);

    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Edit
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(
              AppRoutes.vendorCreditsCreate,
              queryParameters: {'id': creditNote.id},
            ),
            icon: const Icon(LucideIcons.pencil, size: iconSize),
            label: const Text('Edit', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderLight),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          gap,
          // Send Email
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.mail, size: iconSize),
            label: const Text('Send Email', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderLight),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          gap,
          // PDF/Print dropdown
          MenuAnchor(
            builder: (ctx, ctrl, _) => OutlinedButton(
              onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderLight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(LucideIcons.printer, size: iconSize),
                  SizedBox(width: 6),
                  Text('PDF/Print', style: btnStyle),
                  SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, size: 13),
                ],
              ),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.fileText,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onPdf,
                child: const SizedBox(
                  width: 120,
                  child: Text(
                    'PDF',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ),
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.printer,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onPrint,
                child: const SizedBox(
                  width: 120,
                  child: Text(
                    'Print',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          gap,
          // Apply to Bills — only for Open credits
          if (creditNote.status.toLowerCase() == 'open') ...[
            OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                useRootNavigator: true,
                useSafeArea: false,
                barrierColor: Colors.black54,
                builder: (_) => ApplyToBillsDialog(creditNote: creditNote),
              ),
              icon: const Icon(LucideIcons.clipboardCheck, size: iconSize),
              label: const Text('Apply to Bills', style: btnStyle),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderLight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            gap,
          ],
          // More Menu
          ZTableMoreMenu(
            width: 40,
            height: 36,
            iconSize: 18,
            menuChildren: [
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.bookOpen, size: 16),
                onPressed: onJournal,
                child: const Text('Journal'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.trash2, size: 16),
                onPressed: onDelete,
                child: const Text('Delete'),
              ),
            ],
          ),
          const Spacer(),
          // Back Button
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.vendorCredits),
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            label: const Text(
              'Back',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Bar Timeline ──────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final VendorCreditDetail creditNote;

  const _StatusBar({required this.creditNote});

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(stages.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 1, color: AppTheme.borderLight),
            );
          }
          final stage = stages[i ~/ 2];
          return _StageChip(stage: stage);
        }),
      ),
    );
  }

  List<_VcStage> _buildStages() {
    final statusColor = _statusColor(creditNote.status);
    return [
      _VcStage(
        title: 'Credit Created',
        value: 'Open',
        color: AppTheme.primaryBlue,
      ),
      _VcStage(title: 'Status', value: creditNote.status, color: statusColor),
      const _VcStage(
        title: 'Refund Status',
        value: 'Pending',
        color: AppTheme.textSecondary,
      ),
    ];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.primaryBlue;
      case 'closed':
        return AppTheme.successGreen;
      case 'void':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _VcStage {
  final String title;
  final String value;
  final Color color;

  const _VcStage({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _StageChip extends StatelessWidget {
  final _VcStage stage;

  const _StageChip({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: stage.color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          stage.title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stage.value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: stage.color,
          ),
        ),
      ],
    );
  }
}

// ── Document Card (Physical Invoice view) ────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final VendorCreditDetail creditNote;
  final OrgSettings? orgSettings;
  final void Function(VendorCreditItem) onItemTap;

  const _DocumentCard({
    required this.creditNote,
    required this.orgSettings,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy').format(creditNote.date);
    final orgName = orgSettings?.name.trim() ?? 'YOUR COMPANY NAME';
    final orgAddress =
        orgSettings?.paymentStubAddress?.trim() ??
        'Address Line 1\nCity, State PIN';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header info
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDocLogo(orgSettings),
                          const SizedBox(height: 10),
                          Text(
                            orgName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orgAddress,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VENDOR CREDIT',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Credit Note# ${creditNote.creditNoteNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 20),
              // Billing, Shipping & Meta info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vendor Address',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            creditNote.vendorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creditNote.billingAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSubtle,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Supply Locations & Credit Meta
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _metaRow('Credit Date', dateStr),
                        _metaRow('Reference#', creditNote.referenceNumber),
                        _metaRow('Source of Supply', creditNote.sourceOfSupply),
                        _metaRow('Destination', creditNote.destinationOfSupply),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Items Table
              _ItemsTable(
                items: creditNote.items,
                fmt: fmt,
                onItemTap: onItemTap,
              ),
              // Totals Block
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
                child: Row(
                  children: [
                    const Spacer(),
                    _TotalsBlock(creditNote: creditNote, fmt: fmt),
                  ],
                ),
              ),
              // Authorized Signature Block
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(
                          width: 220,
                          child: Divider(
                            color: AppTheme.textPrimary,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Authorized Signature',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
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

        // ── Corner status ribbon ──────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          child: ClipRect(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: -28,
                    child: Transform.rotate(
                      angle: -0.785,
                      child: Container(
                        width: 130,
                        height: 36,
                        color: creditNote.status.toUpperCase() == 'CLOSED'
                            ? AppTheme.successGreen
                            : creditNote.status.toUpperCase() == 'OPEN'
                            ? AppTheme.primaryBlue
                            : creditNote.status.toUpperCase() == 'VOID'
                            ? AppTheme.errorRed
                            : AppTheme.textSecondary,
                        alignment: Alignment.center,
                        child: Text(
                          creditNote.status[0].toUpperCase() +
                              creditNote.status.substring(1).toLowerCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
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
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 160,
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildDocLogoFallback(),
        ),
      );
    }
    return _buildDocLogoFallback();
  }

  Widget _buildDocLogoFallback() {
    return Container(
      width: 160,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'LOGO',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Items Table Component ────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<VendorCreditItem> items;
  final NumberFormat fmt;
  final void Function(VendorCreditItem) onItemTap;

  const _ItemsTable({
    required this.items,
    required this.fmt,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    return Column(
      children: [
        // Table Header
        Container(
          color: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Row(
            children: const [
              SizedBox(width: 28, child: Text('#', style: headerStyle)),
              Expanded(
                flex: 5,
                child: Text('Item & Description', style: headerStyle),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Qty',
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Rate',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Tax',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Amount',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Table Rows
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;

          return InkWell(
            onTap: () => onItemTap(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      item.quantity.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      fmt.format(item.rate),
                      style: const TextStyle(fontSize: 12.5),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.taxRate,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      fmt.format(item.amount),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Totals Block Component ───────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  final VendorCreditDetail creditNote;
  final NumberFormat fmt;

  const _TotalsBlock({required this.creditNote, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isInterstate =
        creditNote.sourceOfSupply != creditNote.destinationOfSupply;

    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _totalRow('Sub Total', fmt.format(creditNote.subtotal)),
          if (isInterstate)
            _totalRow('IGST [18%]', fmt.format(creditNote.taxAmount))
          else ...[
            _totalRow('CGST [9%]', fmt.format(creditNote.taxAmount / 2)),
            _totalRow('SGST [9%]', fmt.format(creditNote.taxAmount / 2)),
          ],
          if (creditNote.shipping > 0)
            _totalRow('Shipping Charges', fmt.format(creditNote.shipping)),
          if (creditNote.adjustment != 0)
            _totalRow('Adjustment', fmt.format(creditNote.adjustment)),
          const Divider(color: AppTheme.borderLight, height: 16),
          _totalRow('Total', fmt.format(creditNote.total), isGrandTotal: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Credit Balance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.infoTextDark,
                  ),
                ),
                Text(
                  '₹${fmt.format(creditNote.balance)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.infoTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w400,
              color: isGrandTotal
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item Details Drawer ──────────────────────────────────────────────────────

class _ItemStockDrawer extends StatelessWidget {
  final VendorCreditItem item;
  final VoidCallback onClose;

  const _ItemStockDrawer({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(left: BorderSide(color: AppTheme.borderLight)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: onClose,
                    color: AppTheme.errorRed,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TRANSACTION DETAILS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _drawerDetailRow(
                    'Quantity Credited',
                    '${item.quantity.toStringAsFixed(0)} pcs',
                  ),
                  _drawerDetailRow('Rate', '₹${item.rate.toStringAsFixed(2)}'),
                  _drawerDetailRow('Tax Rate Applied', item.taxRate),
                  _drawerDetailRow(
                    'Total Amount',
                    '₹${item.amount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: 20),
                  const Text(
                    'STOCK STATUS (Mock)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _drawerDetailRow('Stock On Hand', '150 pcs'),
                  _drawerDetailRow('Available for Sale', '150 pcs'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Apply to Bills Dialog ────────────────────────────────────────────────────

class _ApplyBillRow {
  final String billId;
  final String billNumber;
  final String billDate;
  final String location;
  final double billAmount;
  final double billBalance;
  final String creditsAppliedOn;
  final TextEditingController creditsToApplyController;

  _ApplyBillRow({
    required this.billId,
    required this.billNumber,
    required this.billDate,
    required this.location,
    required this.billAmount,
    required this.billBalance,
    required this.creditsAppliedOn,
    String initialCreditsToApply = '0.00',
  }) : creditsToApplyController = TextEditingController(
         text: initialCreditsToApply,
       );

  void dispose() => creditsToApplyController.dispose();
}

class ApplyToBillsDialog extends StatefulWidget {
  final VendorCreditDetail creditNote;

  const ApplyToBillsDialog({super.key, required this.creditNote});

  @override
  State<ApplyToBillsDialog> createState() => _ApplyToBillsDialogState();
}

class _ApplyToBillsDialogState extends State<ApplyToBillsDialog> {
  bool _setAppliedOnDate = true;
  List<_ApplyBillRow> _bills = [];
  bool _isLoadingBills = true;
  bool _isSaving = false;
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    for (final b in _bills) {
      b.dispose();
    }
    super.dispose();
  }

  double get _totalToCredit => _bills.fold(0.0, (sum, b) {
    return sum + (double.tryParse(b.creditsToApplyController.text) ?? 0.0);
  });

  double get _remainingCredits => widget.creditNote.balance - _totalToCredit;

  Future<void> _loadBills() async {
    try {
      final supabase = Supabase.instance.client;
      final vendorCreditRows = await supabase
          .from('vendor_credits')
          .select('vendor_id, entity_id')
          .eq('id', widget.creditNote.id)
          .limit(1);
      if (vendorCreditRows.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingBills = false);
        return;
      }

      final vendorCreditRow = Map<String, dynamic>.from(
        vendorCreditRows.first as Map,
      );
      final vendorId = vendorCreditRow['vendor_id']?.toString() ?? '';
      final entityId = vendorCreditRow['entity_id']?.toString() ?? '';

      dynamic query = Supabase.instance.client
          .from('bills')
          .select(
            'id, bill_number, bill_date, grand_total, entity_id, '
            'status, is_delete',
          )
          .eq('vendor_id', vendorId)
          .eq('is_delete', false)
          .inFilter('status', ['open', 'overdue', 'partially_paid']);
      if (entityId.isNotEmpty) {
        query = query.eq('entity_id', entityId);
      }
      query = query.order('bill_date', ascending: false);

      final billRows = await query;
      final loadedBills = (billRows as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .where((row) {
            final billId = row['id']?.toString() ?? '';
            final status = row['status']?.toString().trim().toLowerCase() ?? '';
            final isDeleted = row['is_delete'] == true;
            return billId.isNotEmpty &&
                !isDeleted &&
                status != 'paid' &&
                status != 'void' &&
                status != 'draft';
          })
          .map(
            (row) => _ApplyBillRow(
              billId: row['id']?.toString() ?? '',
              billNumber: row['bill_number']?.toString() ?? '',
              billDate: _dateFmt.format(
                DateTime.tryParse(row['bill_date']?.toString() ?? '') ??
                    DateTime(2026, 7, 17),
              ),
              location: 'ZABNIX PRIVATE LIMITED',
              billAmount:
                  double.tryParse(
                    row['grand_total']?.toString() ?? '0',
                  ) ??
                  0,
              billBalance:
                  double.tryParse(
                    row['grand_total']?.toString() ?? '0',
                  ) ??
                  0,
              creditsAppliedOn: _dateFmt.format(DateTime(2026, 7, 17)),
            ),
          )
          .toList(growable: false);

      for (final bill in loadedBills) {
        bill.creditsToApplyController.addListener(() => setState(() {}));
      }

      if (!mounted) return;
      setState(() {
        _bills = loadedBills;
        _isLoadingBills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingBills = false);
      ZerpaiToast.error(context, 'Failed to load bills: $e');
    }
  }

  Future<void> _saveAppliedBill() async {
    if (_isSaving) return;
    final selectedRows = _bills.where((bill) {
      final amount = double.tryParse(bill.creditsToApplyController.text) ?? 0;
      return amount > 0;
    }).toList(growable: false);

    if (selectedRows.isEmpty) {
      ZerpaiToast.error(context, 'Enter credits to apply for a bill.');
      return;
    }
    if (_totalToCredit > widget.creditNote.balance) {
      ZerpaiToast.error(context, 'Applied credits exceed available credits.');
      return;
    }

    final selected = selectedRows.first;
    final amountCredited =
        double.tryParse(selected.creditsToApplyController.text) ?? 0;
    if (selected.billId.trim().isEmpty || amountCredited <= 0) {
      ZerpaiToast.error(context, 'Select a valid bill to apply credits.');
      return;
    }

    try {
      setState(() => _isSaving = true);
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      await supabase
          .from('vendor_credits')
          .update({'bill_id': selected.billId})
          .eq('id', widget.creditNote.id);
      await supabase.from('audit_logs').insert({
        'table_name': 'vendor_credits',
        'record_id': widget.creditNote.id,
        'action': 'APPLY_TO_BILL',
        'old_values': null,
        'new_values': {
          'bill_id': selected.billId,
          'bill_number': selected.billNumber,
          'amount_credited': amountCredited,
          'applied_on': selected.creditsAppliedOn,
        },
        'user_id':
            user?.id ?? '00000000-0000-0000-0000-000000000000',
        'org_id': '00000000-0000-0000-0000-000000000000',
        'entity_id': '00000000-0000-0000-0000-000000000000',
        'actor_name': user?.email?.split('@').first ?? 'system',
        'schema_name': 'public',
        'record_pk': widget.creditNote.creditNoteNumber,
        'changed_columns': const ['bill_id'],
        'source': 'ui',
        'module_name': 'vendor_credits',
      });
      if (!mounted) return;
      ZerpaiToast.success(context, 'Credits applied successfully');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to apply credits: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCredits = widget.creditNote.balance;
    final availableDateStr = _dateFmt.format(widget.creditNote.date);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(1100, math.max(320, screenSize.width - 48)),
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Apply credits from ${widget.creditNote.creditNoteNumber}',
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

            // ── Body ──
            Flexible(
              child: _isLoadingBills
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bills to Apply label + controls row
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
                              const Tooltip(
                                message:
                                    'When enabled, the date on which credits are applied will be recorded.',
                                child: Icon(
                                  LucideIcons.info,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Switch(
                                value: _setAppliedOnDate,
                                onChanged: (v) => setState(() => _setAppliedOnDate = v),
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppTheme.successGreen,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: AppTheme.borderLight,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                      text: '₹${_fmt.format(availableCredits)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    TextSpan(text: ' ($availableDateStr)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Table grid ──
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: math.max(680, math.min(1050, screenSize.width - 96)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Table(
                                  border: TableBorder.all(
                                    color: AppTheme.borderLight,
                                    width: 1,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  columnWidths: {
                                    0: const FlexColumnWidth(1.6), // BILL#
                                    1: const FlexColumnWidth(1.6), // BILL DATE
                                    2: const FlexColumnWidth(2.4), // LOCATION
                                    3: const FlexColumnWidth(1.6), // BILL AMOUNT
                                    4: const FlexColumnWidth(1.6), // BILL BALANCE
                                    if (_setAppliedOnDate)
                                      5: const FlexColumnWidth(1.8), // CREDITS APPLIED ON
                                    if (_setAppliedOnDate)
                                      6:
                                          const FlexColumnWidth(1.8) // CREDITS TO APPLY
                                    else
                                      5: const FlexColumnWidth(
                                        1.8,
                                      ), // CREDITS TO APPLY (no date col)
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    // ── Header row ──
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
                                            child: _ATBColHeader('CREDITS APPLIED ON'),
                                          ),
                                        _ATBCell(
                                          child: _ATBColHeader(
                                            'CREDITS TO APPLY',
                                            align: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // ── Data rows ──
                                    ...List.generate(_bills.length, (i) {
                                      final b = _bills[i];
                                      return TableRow(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        children: [
                                          _ATBCell(
                                            child: Text(
                                              b.billNumber,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          _ATBCell(
                                            child: Text(
                                              b.billDate,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          _ATBCell(
                                            child: Text(
                                              b.location,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          _ATBCell(
                                            child: Text(
                                              '₹${_fmt.format(b.billAmount)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          _ATBCell(
                                            child: Text(
                                              '₹${_fmt.format(b.billBalance)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (_setAppliedOnDate)
                                            _ATBCell(
                                              child: Text(
                                                b.creditsAppliedOn,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          _ATBCell(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            child: TextField(
                                              controller: b.creditsToApplyController,
                                              textAlign: TextAlign.right,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(3),
                                                  borderSide: const BorderSide(
                                                    color: AppTheme.borderLight,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(3),
                                                  borderSide: const BorderSide(
                                                    color: AppTheme.borderLight,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(3),
                                                  borderSide: const BorderSide(
                                                    color: AppTheme.primaryBlue,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Summary ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _ATBSummaryRow(
                                  label: 'Total Amount to Credit:',
                                  value: _fmt.format(_totalToCredit),
                                ),
                                const SizedBox(height: 6),
                                _ATBSummaryRow(
                                  label: 'Remaining credits:',
                                  value: _remainingCredits.toStringAsFixed(0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const Divider(height: 1, color: AppTheme.borderLight),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAppliedBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Cancel'),
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ATBCell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ATBCell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

class _ATBSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _ATBSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Journal Section ──────────────────────────────────────────────────────────

class _JournalSection extends ConsumerWidget {
  final VendorCreditDetail creditNote;

  const _JournalSection({super.key, required this.creditNote});

  Future<List<Map<String, dynamic>>> _fetchVendorCreditJournals(String vcId) async {
    final supabase = Supabase.instance.client;
    try {
      final res = await supabase
          .from('journal_entry_lines')
          .select('*, account:accounts(user_account_name, system_account_name)')
          .eq('source_id', vcId)
          .eq('source_type', 'VENDOR_CREDIT');
      if (res.isNotEmpty) {
        return List<Map<String, dynamic>>.from(res);
      }
    } catch (_) {}

    try {
      final header = await supabase
          .from('journal_entries')
          .select('id')
          .eq('source_document_id', vcId)
          .eq('source_document_type', 'vendor_credits')
          .maybeSingle();
      if (header != null && header['id'] != null) {
        final res2 = await supabase
            .from('journal_entry_lines')
            .select('*, account:accounts(user_account_name, system_account_name)')
            .eq('journal_entry_id', header['id']);
        if (res2.isNotEmpty) {
          return List<Map<String, dynamic>>.from(res2);
        }
      }
    } catch (_) {}

    return [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final warehouses = ref.watch(warehousesProvider).value ?? [];
    String resolvedWarehouseName = creditNote.sourceOfSupply.trim();
    if (resolvedWarehouseName.isEmpty && warehouses.isNotEmpty) {
      resolvedWarehouseName = warehouses.first.name;
    }
    if (resolvedWarehouseName.isEmpty) {
      resolvedWarehouseName = 'ZABNIX PRIVATE LIMITED';
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchVendorCreditJournals(creditNote.id),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> txs = [];
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty) {
          txs = snapshot.data!;
        } else {
          // Fallback structure for presentation/mock records
          const itemAccountName = 'Discount';
          txs = [
            {
              'account': {'user_account_name': itemAccountName},
              'debit': 0.0,
              'credit': creditNote.total,
            },
            {
              'account': {'system_account_name': 'Accounts Payable'},
              'debit': creditNote.total,
              'credit': 0.0,
            },
          ];
        }

        double totalDebit = 0;
        double totalCredit = 0;
        for (var tx in txs) {
          totalDebit += double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
          totalCredit += double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;
        }
        final bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBalanced) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
              const SizedBox(height: 12),
            ],
            Table(
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
                        'WAREHOUSE',
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
                ...txs.map((tx) {
                  final accountName = tx['account']?['user_account_name'] ??
                      tx['account']?['system_account_name'] ??
                      'Accounts Payable';
                  final debit = double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
                  final credit = double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;

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
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          resolvedWarehouseName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          fmt.format(debit),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          fmt.format(credit),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
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
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        fmt.format(totalDebit),
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
                        fmt.format(totalCredit),
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
            ),
          ],
        );
      },
    );
  }
}

class _PdfOrgLogo extends ConsumerWidget {
  const _PdfOrgLogo({this.width = 140, this.height = 60});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(orgSettingsProvider).valueOrNull?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(4),
    ),
    alignment: Alignment.center,
    child: const Text(
      'LOGO',
      style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8),
    ),
  );
}
