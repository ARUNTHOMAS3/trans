import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/providers/purchases_purchase_returns_provider.dart';

// ── Display models ────────────────────────────────────────────────────────────

class PurchaseReturnDetailData {
  final String id;
  final String returnNumber;
  final DateTime date;
  final String vendorName;
  final String vendorAddress;
  final String? purchaseOrderNumber;
  final String? purchaseReceiveNumber;
  final String? billNumber;
  final String warehouseName;
  final String sourceOfSupply;
  final String destinationOfSupply;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double shipping;
  final double adjustment;
  final double total;
  final double balance;
  final List<PurchaseReturnDetailItemData> items;
  final List<ReceiveBatch> receiveHistory;

  const PurchaseReturnDetailData({
    required this.id,
    required this.returnNumber,
    required this.date,
    required this.vendorName,
    required this.vendorAddress,
    this.purchaseOrderNumber,
    this.purchaseReceiveNumber,
    this.billNumber,
    required this.warehouseName,
    required this.sourceOfSupply,
    required this.destinationOfSupply,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    this.shipping = 0.0,
    this.adjustment = 0.0,
    required this.total,
    required this.balance,
    required this.items,
    this.receiveHistory = const [],
  });
}

class PurchaseReturnDetailItemData {
  final String name;
  final String description;
  final double returnQty;
  final String unit;
  final double rate;
  final String taxRate;
  final double amount;
  final String? reason;

  const PurchaseReturnDetailItemData({
    required this.name,
    required this.description,
    required this.returnQty,
    required this.unit,
    required this.rate,
    required this.taxRate,
    required this.amount,
    this.reason,
  });
}

class ReceiveBatchLine {
  final String itemName;
  final double qty;
  final String unit;

  const ReceiveBatchLine({
    required this.itemName,
    required this.qty,
    required this.unit,
  });
}

class ReceiveBatch {
  final String receiveNumber;
  final DateTime date;
  final List<ReceiveBatchLine> items;

  const ReceiveBatch({
    required this.receiveNumber,
    required this.date,
    required this.items,
  });
}

// ── Mock data provider ────────────────────────────────────────────────────────

// ── Dynamic data provider ─────────────────────────────────────────────────────

final purchaseReturnDetailProvider =
    Provider.family<PurchaseReturnDetailData?, String>((ref, id) {
  final returnsAsync = ref.watch(purchaseReturnsProvider);
  final returnsState = returnsAsync.valueOrNull;
  final returnsList = returnsState?.returns ?? [];

  final match = returnsList
      .where((r) => r.id == id || r.returnNumber == id)
      .firstOrNull;

  if (match == null) return null;

  return PurchaseReturnDetailData(
    id: match.id ?? match.returnNumber,
    returnNumber: match.returnNumber,
    date: match.returnDate ?? DateTime.now(),
    vendorName: match.vendorName ?? '',
    vendorAddress: '',
    purchaseOrderNumber: match.purchaseOrderNumber,
    purchaseReceiveNumber: match.purchaseReceiveNumber,
    billNumber: match.billNumber,
    warehouseName: match.warehouseName ?? '',
    sourceOfSupply: '',
    destinationOfSupply: '',
    status: match.status,
    subtotal: match.subtotal,
    taxAmount: match.taxAmount,
    total: match.total,
    balance: match.total,
    items: match.items
        .map(
          (i) => PurchaseReturnDetailItemData(
            name: i.itemName,
            description: i.description ?? '',
            returnQty: i.returnQty,
            unit: i.unit ?? 'Pcs',
            rate: i.rate,
            taxRate: i.taxRateName ?? '0%',
            amount: i.amount,
            reason: i.reason,
          ),
        )
        .toList(),
  );
});

// ── Page ──────────────────────────────────────────────────────────────────────

class PurchaseReturnDetailPage extends ConsumerStatefulWidget {
  final String purchaseReturnId;

  const PurchaseReturnDetailPage({super.key, required this.purchaseReturnId});

  @override
  ConsumerState<PurchaseReturnDetailPage> createState() =>
      _PurchaseReturnDetailPageState();
}

class _PurchaseReturnDetailPageState
    extends ConsumerState<PurchaseReturnDetailPage> {
  PurchaseReturnDetailItemData? _drawerItem;
  bool _showJournal = false;
  List<ReceiveBatch> _localReceiveHistory = [];
  bool _showPdfView = false;

  void _openItemDrawer(PurchaseReturnDetailItemData item) {
    setState(() => _drawerItem = item);
  }

  void _closeItemDrawer() {
    setState(() => _drawerItem = null);
  }

  void _showRecordReceiveDialog(
      BuildContext context, PurchaseReturnDetailData returnDetail) {
    showDialog<ReceiveBatch?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => RecordReceiveDialog(returnDetail: returnDetail),
    ).then((batch) {
      if (batch != null && mounted) {
        setState(() => _localReceiveHistory.add(batch));
      }
    });
  }

  Widget _buildPrPdfCard(PurchaseReturnDetailData returnDetail, OrgSettings? orgSettings) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy').format(returnDetail.date);

    Color ribbonColor;
    switch (returnDetail.status.toLowerCase()) {
      case 'confirmed': ribbonColor = AppTheme.primaryBlue; break;
      case 'vendor_received': ribbonColor = AppTheme.successGreen; break;
      default: ribbonColor = const Color(0xFF5B6B7C);
    }
    String ribbonLabel;
    switch (returnDetail.status.toLowerCase()) {
      case 'confirmed': ribbonLabel = 'Confirmed'; break;
      case 'vendor_received': ribbonLabel = 'Received'; break;
      default: ribbonLabel = 'Draft';
    }

    return Container(
      key: const ValueKey('pr-pdf'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
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
                            orgSettings?.name.trim().isNotEmpty == true ? orgSettings!.name.trim() : 'YOUR COMPANY NAME',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orgSettings?.paymentStubAddress?.trim() ?? 'Address Line 1\nCity, State PIN',
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('PURCHASE RETURN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('Return# ${returnDetail.returnNumber}', style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
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
                          const Text('VENDOR ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.4)),
                          const SizedBox(height: 6),
                          Text(returnDetail.vendorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlueDark)),
                          const SizedBox(height: 4),
                          Text(returnDetail.vendorAddress, style: const TextStyle(fontSize: 12, color: AppTheme.textSubtle, height: 1.5)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _pdfMetaRow('Return Date', dateStr),
                        if (returnDetail.purchaseOrderNumber != null)
                          _pdfMetaRow('Purchase Order', returnDetail.purchaseOrderNumber!),
                        if (returnDetail.purchaseReceiveNumber != null)
                          _pdfMetaRow('Receive#', returnDetail.purchaseReceiveNumber!),
                        if (returnDetail.billNumber != null)
                          _pdfMetaRow('Bill#', returnDetail.billNumber!),
                        _pdfMetaRow('Warehouse', returnDetail.warehouseName),
                        _pdfMetaRow('Source of Supply', returnDetail.sourceOfSupply),
                        _pdfMetaRow('Destination', returnDetail.destinationOfSupply),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ItemsTable(items: returnDetail.items, fmt: fmt, onItemTap: (_) {}),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
                  child: Row(
                    children: [
                      const Spacer(),
                      _TotalsBlock(returnDetail: returnDetail, fmt: fmt),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(width: 220, child: Divider(color: AppTheme.textPrimary, thickness: 1)),
                        SizedBox(height: 4),
                        Text('Authorized Signature', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
            child: _PdfCornerRibbon(
              label: ribbonLabel,
              color: ribbonColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 140,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPdfLogoFallback(),
        ),
      );
    }
    return _buildPdfLogoFallback();
  }

  Widget _buildPdfLogoFallback() {
    return Container(
      width: 140,
      height: 60,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO',
          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.8),
        ),
      ),
    );
  }

  Widget _pdfMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label : ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final returnDetail = ref.watch(
      purchaseReturnDetailProvider(widget.purchaseReturnId),
    );
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;

    if (returnDetail == null) {
      return const ZerpaiLayout(
        pageTitle: 'Purchase Return Detail',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('Purchase return not found.'),
          ),
        ),
      );
    }

    return ZerpaiLayout(
      pageTitle: returnDetail.returnNumber,
      enableBodyScroll: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionBar(
                returnDetail: returnDetail,
                onDelete: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete action triggered (Mocked)'),
                    ),
                  );
                  context.go(AppRoutes.purchaseReturns);
                },
                onJournal: () => setState(() => _showJournal = !_showJournal),
                onRecordReceive: returnDetail.status.toLowerCase() == 'confirmed'
                    ? () => _showRecordReceiveDialog(context, returnDetail)
                    : null,
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              _StatusBar(returnDetail: returnDetail),
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
                                onChanged: (v) => setState(() => _showPdfView = v),
                                activeTrackColor: AppTheme.primaryBlue,
                                activeThumbColor: Colors.white,
                                inactiveTrackColor: AppTheme.borderLight,
                                inactiveThumbColor: Colors.white,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _showPdfView
                                ? _buildPrPdfCard(returnDetail, orgSettings)
                                : _DocumentCard(
                                    returnDetail: returnDetail,
                                    orgSettings: orgSettings,
                                    onItemTap: _openItemDrawer,
                                  ),
                          ),
                          const SizedBox(height: 24),
                          _ReceiveBatchesSection(
                            returnDetail: returnDetail,
                            receiveBatches: [
                              ...returnDetail.receiveHistory,
                              ..._localReceiveHistory,
                            ],
                            onRecordReceive: returnDetail.status.toLowerCase() != 'draft'
                                ? () => _showRecordReceiveDialog(context, returnDetail)
                                : null,
                          ),
                          if (_showJournal) ...[
                            const SizedBox(height: 24),
                            _JournalSection(returnDetail: returnDetail),
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
            _ItemStockDrawer(
                item: _drawerItem!, onClose: _closeItemDrawer),
        ],
      ),
    );
  }
}

// ── Action Bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatefulWidget {
  final PurchaseReturnDetailData returnDetail;
  final VoidCallback onDelete;
  final VoidCallback onJournal;
  final VoidCallback? onRecordReceive;

  const _ActionBar({
    required this.returnDetail,
    required this.onDelete,
    required this.onJournal,
    this.onRecordReceive,
  });

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  final LayerLink _pdfPrintLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;

  @override
  void dispose() {
    _pdfPrintOverlay?.remove();
    super.dispose();
  }

  void _showPdfPrintMenu() {
    if (_pdfPrintOverlay != null) return;
    final overlay = Overlay.of(context);
    _pdfPrintOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePdfPrintMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _pdfPrintLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 36),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 160,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PrDownloadMenuOption(
                      icon: LucideIcons.fileText,
                      label: 'PDF',
                      onTap: _closePdfPrintMenu,
                    ),
                    _PrDownloadMenuOption(
                      icon: LucideIcons.printer,
                      label: 'Print',
                      onTap: _closePdfPrintMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_pdfPrintOverlay!);
  }

  void _closePdfPrintMenu() {
    _pdfPrintOverlay?.remove();
    _pdfPrintOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 4);
    final status = widget.returnDetail.status.toLowerCase();

    return Material(
      color: Colors.white,
      child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _PrOverviewBtn(
            icon: LucideIcons.pencil,
            label: 'Edit',
            onTap: () => context.push(
              '${AppRoutes.purchaseReturnsCreate}?id=${widget.returnDetail.id}',
            ),
          ),
          gap,
          _PrOverviewBtn(
            icon: LucideIcons.mail,
            label: 'Send Email',
            onTap: () {},
          ),
          gap,
          CompositedTransformTarget(
            link: _pdfPrintLink,
            child: _PrOverviewBtn(
              icon: LucideIcons.fileText,
              label: 'PDF/Print',
              trailingIcon: LucideIcons.chevronDown,
              onTap: _showPdfPrintMenu,
            ),
          ),
          gap,
          if (status == 'draft') ...[
            _PrOverviewBtn(
              icon: LucideIcons.checkCircle,
              label: 'Confirm',
              onTap: () {},
              color: AppTheme.primaryBlue,
            ),
            gap,
          ],

          _PrOverviewMoreBtn(
            onJournal: widget.onJournal,
            onDelete: widget.onDelete,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.purchaseReturns),
            icon: const Icon(LucideIcons.chevronLeft,
                size: 14, color: AppTheme.textSecondary),
            label: const Text('Back',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;

  const _StatusBar({required this.returnDetail});

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

  List<_PrStage> _buildStages() {
    final statusColor = _statusColor(returnDetail.status);
    final statusLabel = _statusLabel(returnDetail.status);
    return [
      const _PrStage(
        title: 'Return Created',
        value: 'Recorded',
        color: AppTheme.successGreen,
      ),
      _PrStage(title: 'Status', value: statusLabel, color: statusColor),
      const _PrStage(
        title: 'Refund Status',
        value: 'Pending',
        color: AppTheme.textSecondary,
      ),
    ];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryBlue;
      case 'vendor_received':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'vendor_received':
        return 'Vendor Received';
      default:
        return 'Draft';
    }
  }
}

class _PrStage {
  final String title;
  final String value;
  final Color color;

  const _PrStage({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _StageChip extends StatelessWidget {
  final _PrStage stage;

  const _StageChip({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: stage.color,
            shape: BoxShape.circle,
          ),
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

// ── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;
  final OrgSettings? orgSettings;
  final void Function(PurchaseReturnDetailItemData) onItemTap;

  const _DocumentCard({
    required this.returnDetail,
    required this.orgSettings,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr =
        DateFormat('dd-MM-yyyy').format(returnDetail.date);
    final orgName =
        orgSettings?.name.trim() ?? 'YOUR COMPANY NAME';
    final orgAddress =
        orgSettings?.paymentStubAddress?.trim() ??
        'Address Line 1\nCity, State PIN';

    final ribbonColor = _ribbonColor(returnDetail.status);
    final ribbonLabel = _ribbonLabel(returnDetail.status);

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
                          'PURCHASE RETURN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Return# ${returnDetail.returnNumber}',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            returnDetail.vendorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            returnDetail.vendorAddress,
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
                        _metaRow('Return Date', dateStr),
                        if (returnDetail.purchaseOrderNumber != null)
                          _metaRow('Purchase Order', returnDetail.purchaseOrderNumber!),
                        if (returnDetail.purchaseReceiveNumber != null)
                          _metaRow('Receive#', returnDetail.purchaseReceiveNumber!),
                        if (returnDetail.billNumber != null)
                          _metaRow('Bill#', returnDetail.billNumber!),
                        _metaRow('Warehouse', returnDetail.warehouseName),
                        _metaRow('Source of Supply', returnDetail.sourceOfSupply),
                        _metaRow('Destination', returnDetail.destinationOfSupply),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ItemsTable(
                items: returnDetail.items,
                fmt: fmt,
                onItemTap: onItemTap,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
                child: Row(
                  children: [
                    const Spacer(),
                    _TotalsBlock(returnDetail: returnDetail, fmt: fmt),
                  ],
                ),
              ),
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
                          ribbonLabel,
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

  Color _ribbonColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryBlue;
      case 'vendor_received':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _ribbonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'vendor_received':
        return 'Received';
      default:
        return 'Draft';
    }
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
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
        style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8),
      ),
    );
  }
}

// ── Items Table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<PurchaseReturnDetailItemData> items;
  final NumberFormat fmt;
  final void Function(PurchaseReturnDetailItemData) onItemTap;

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
                child: Text('Return Qty', style: headerStyle,
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 60,
                child: Text('Unit', style: headerStyle,
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 90,
                child: Text('Rate', style: headerStyle,
                    textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 100,
                child: Text('Tax', style: headerStyle,
                    textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 100,
                child: Text('Amount', style: headerStyle,
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return InkWell(
            onTap: () => onItemTap(item),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary)),
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
                          Text(item.description,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary)),
                        ],
                        if (item.reason != null) ...[
                          const SizedBox(height: 2),
                          Text('Reason: ${item.reason}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(item.returnQty.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12.5),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(item.unit,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary),
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(fmt.format(item.rate),
                        style: const TextStyle(fontSize: 12.5),
                        textAlign: TextAlign.right),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(item.taxRate,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary),
                        textAlign: TextAlign.right),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(fmt.format(item.amount),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.right),
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

// ── Totals Block ──────────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;
  final NumberFormat fmt;

  const _TotalsBlock({required this.returnDetail, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isInterstate =
        returnDetail.sourceOfSupply != returnDetail.destinationOfSupply;

    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _totalRow('Sub Total', fmt.format(returnDetail.subtotal)),
          if (isInterstate)
            _totalRow('IGST [18%]', fmt.format(returnDetail.taxAmount))
          else ...[
            _totalRow('CGST [9%]', fmt.format(returnDetail.taxAmount / 2)),
            _totalRow('SGST [9%]', fmt.format(returnDetail.taxAmount / 2)),
          ],
          if (returnDetail.shipping > 0)
            _totalRow('Shipping Charges', fmt.format(returnDetail.shipping)),
          if (returnDetail.adjustment != 0)
            _totalRow('Adjustment', fmt.format(returnDetail.adjustment)),
          const Divider(color: AppTheme.borderLight, height: 16),
          _totalRow('Total', fmt.format(returnDetail.total),
              isGrandTotal: true),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Return Balance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.infoTextDark,
                  ),
                ),
                Text(
                  '₹${fmt.format(returnDetail.balance)}',
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

  Widget _totalRow(String label, String value,
      {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight:
                  isGrandTotal ? FontWeight.w800 : FontWeight.w400,
              color: isGrandTotal
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight:
                  isGrandTotal ? FontWeight.w800 : FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item Stock Drawer ─────────────────────────────────────────────────────────

class _ItemStockDrawer extends StatelessWidget {
  final PurchaseReturnDetailItemData item;
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
          border:
              const Border(left: BorderSide(color: AppTheme.borderLight)),
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
                    'RETURN DETAILS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Return Qty',
                      '${item.returnQty.toStringAsFixed(0)} ${item.unit}'),
                  _detailRow('Rate', '₹${item.rate.toStringAsFixed(2)}'),
                  _detailRow('Tax Rate', item.taxRate),
                  _detailRow('Amount', '₹${item.amount.toStringAsFixed(2)}'),
                  if (item.reason != null)
                    _detailRow('Return Reason', item.reason!),
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
                  _detailRow('Stock On Hand', '150 pcs'),
                  _detailRow('Available for Sale', '150 pcs'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ── Journal Section ───────────────────────────────────────────────────────────

class _JournalSection extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;

  const _JournalSection({required this.returnDetail});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final entries = _journalEntries();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.bookOpen,
                    size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Journal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Text(
                  returnDetail.returnNumber,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            color: AppTheme.backgroundColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text('Account',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ),
                SizedBox(
                  width: 140,
                  child: Text('Debit',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ),
                SizedBox(
                  width: 140,
                  child: Text('Credit',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          ...entries.map((e) => _JournalRow(entry: e, fmt: fmt)),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text('Total',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    fmt.format(
                        entries.fold(0.0, (s, e) => s + e.debit)),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    fmt.format(
                        entries.fold(0.0, (s, e) => s + e.credit)),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_JournalEntry> _journalEntries() {
    return [
      _JournalEntry(
          account: 'Accounts Payable',
          debit: returnDetail.total,
          credit: 0),
      _JournalEntry(
          account: 'Purchase Returns & Allowances',
          debit: 0,
          credit: returnDetail.subtotal),
      if (returnDetail.taxAmount > 0)
        _JournalEntry(
            account: 'Input Tax Credit Reversal (GST)',
            debit: 0,
            credit: returnDetail.taxAmount),
    ];
  }
}

class _JournalEntry {
  final String account;
  final double debit;
  final double credit;

  const _JournalEntry({
    required this.account,
    required this.debit,
    required this.credit,
  });
}

class _JournalRow extends StatelessWidget {
  final _JournalEntry entry;
  final NumberFormat fmt;

  const _JournalRow({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(entry.account,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary)),
          ),
          SizedBox(
            width: 140,
            child: Text(
              entry.debit > 0 ? fmt.format(entry.debit) : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              entry.credit > 0 ? fmt.format(entry.credit) : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Receive Batches Section ───────────────────────────────────────────────────

class _ReceiveBatchesSection extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;
  final List<ReceiveBatch> receiveBatches;
  final VoidCallback? onRecordReceive;

  const _ReceiveBatchesSection({
    required this.returnDetail,
    required this.receiveBatches,
    this.onRecordReceive,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd-MM-yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.packageCheck,
                    size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Receive Batches',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (onRecordReceive != null)
                  OutlinedButton.icon(
                    onPressed: onRecordReceive,
                    icon: const Icon(LucideIcons.plus, size: 13),
                    label: const Text(
                      'Record Receive',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: const BorderSide(color: AppTheme.successGreen),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
              ],
            ),
          ),
          // Table header
          if (receiveBatches.isNotEmpty)
            Container(
              color: AppTheme.backgroundColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  SizedBox(
                    width: 32,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Receive#',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Items',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text('Total Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text('Status',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
          if (receiveBatches.isNotEmpty)
            const Divider(height: 1, color: AppTheme.borderLight),
          // Rows
          if (receiveBatches.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Text(
                  'No receive batches recorded yet.',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...receiveBatches.asMap().entries.map((entry) {
              final idx = entry.key;
              final batch = entry.value;
              final totalQty =
                  batch.items.fold(0.0, (s, l) => s + l.qty);
              final itemsSummary = batch.items
                  .map((l) => '${l.itemName} (${l.qty.toStringAsFixed(0)} ${l.unit})')
                  .join(', ');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: idx < receiveBatches.length - 1
                              ? AppTheme.borderLight
                              : Colors.transparent)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('${idx + 1}',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        batch.receiveNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateFmt.format(batch.date),
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        itemsSummary,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        totalQty.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'Received',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Record Receive Dialog ─────────────────────────────────────────────────────

class RecordReceiveDialog extends StatefulWidget {
  final PurchaseReturnDetailData returnDetail;

  const RecordReceiveDialog({super.key, required this.returnDetail});

  @override
  State<RecordReceiveDialog> createState() => _RecordReceiveDialogState();
}

class _RecordReceiveDialogState extends State<RecordReceiveDialog> {
  late final List<TextEditingController> _qtyControllers;
  late final String _receiveDateStr;

  @override
  void initState() {
    super.initState();
    _receiveDateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _qtyControllers = widget.returnDetail.items
        .map((item) =>
            TextEditingController(text: item.returnQty.toStringAsFixed(0)))
        .toList();
    for (final c in _qtyControllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final receiveNumber =
        'RCV-${(DateTime.now().millisecondsSinceEpoch % 90000 + 10000)}';
    final lines = widget.returnDetail.items
        .asMap()
        .entries
        .map((e) {
          final qty =
              double.tryParse(_qtyControllers[e.key].text) ?? 0.0;
          return ReceiveBatchLine(
            itemName: e.value.name,
            qty: qty,
            unit: e.value.unit,
          );
        })
        .where((l) => l.qty > 0)
        .toList();

    final batch = ReceiveBatch(
      receiveNumber: receiveNumber,
      date: DateTime.now(),
      items: lines,
    );
    Navigator.of(context).pop(batch);
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, minWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.packageCheck,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Record Vendor Receive — ${widget.returnDetail.returnNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Date row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Receive Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _receiveDateStr,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Table header
            Container(
              color: AppTheme.backgroundColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Table(
                border: TableBorder.all(color: Colors.transparent),
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FixedColumnWidth(90),
                  2: FixedColumnWidth(70),
                  3: FixedColumnWidth(120),
                },
                children: [
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Item Name', style: headerStyle),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Return Qty',
                            textAlign: TextAlign.center,
                            style: headerStyle),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Unit',
                            textAlign: TextAlign.center,
                            style: headerStyle),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Qty to Record',
                            textAlign: TextAlign.center,
                            style: headerStyle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Table rows
            Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FixedColumnWidth(90),
                2: FixedColumnWidth(70),
                3: FixedColumnWidth(120),
              },
              children: widget.returnDetail.items.asMap().entries.map((e) {
                final item = e.value;
                final ctrl = _qtyControllers[e.key];
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        item.returnQty.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        item.unit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: TextField(
                        controller: ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide:
                                const BorderSide(color: AppTheme.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide:
                                const BorderSide(color: AppTheme.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(3),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            // Footer
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: const Text('Save Receive',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
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

// ── PDF/Print dropdown menu option ────────────────────────────────────────────

class _PrDownloadMenuOption extends StatefulWidget {
  const _PrDownloadMenuOption({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_PrDownloadMenuOption> createState() => _PrDownloadMenuOptionState();
}

class _PrDownloadMenuOptionState extends State<_PrDownloadMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: _hovered ? Colors.white : AppTheme.primaryBlue),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action bar hover button (matches vendor credit report _DetailActionBtn) ───

class _PrOverviewBtn extends StatefulWidget {
  const _PrOverviewBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingIcon,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final Color? color;

  @override
  State<_PrOverviewBtn> createState() => _PrOverviewBtnState();
}

class _PrOverviewBtnState extends State<_PrOverviewBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppTheme.textSecondary;
    final textColor = widget.color ?? AppTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? AppTheme.borderLight : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(widget.trailingIcon, size: 12, color: iconColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── More button with hover ────────────────────────────────────────────────────

class _PrOverviewMoreBtn extends StatelessWidget {
  const _PrOverviewMoreBtn({required this.onJournal, required this.onDelete});
  final VoidCallback onJournal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (ctx, ctrl, _) => InkWell(
        onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        hoverColor: AppTheme.bgLight,
        splashColor: Colors.transparent,
        highlightColor: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(LucideIcons.moreHorizontal, size: 15, color: AppTheme.textSecondary),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.trash2, size: 14, color: AppTheme.errorRed),
          onPressed: onDelete,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? AppTheme.primaryBlue : Colors.white),
            foregroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.errorRed),
            iconColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.errorRed),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            minimumSize: const WidgetStatePropertyAll(Size(170, 0)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          ),
          child: const Text('Delete', style: TextStyle(fontSize: 13)),
        ),
      ],
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
        child: const Text('LOGO',
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8)),
      );
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
                      color: Colors.black.withValues(alpha: 0.25),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
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

