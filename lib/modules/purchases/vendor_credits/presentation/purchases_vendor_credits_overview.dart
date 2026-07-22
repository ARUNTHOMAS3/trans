import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ── Models & State ───────────────────────────────────────────────────────────

class VendorCreditDetail {
  final String id;
  final String creditNoteNumber;
  final String referenceNumber;
  final DateTime date;
  final String vendorName;
  final String billingAddress;
  final String destinationOfSupply;
  final String sourceOfSupply;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double shipping;
  final double adjustment;
  final double total;
  final double balance;
  final List<VendorCreditItem> items;

  const VendorCreditDetail({
    required this.id,
    required this.creditNoteNumber,
    required this.referenceNumber,
    required this.date,
    required this.vendorName,
    required this.billingAddress,
    required this.destinationOfSupply,
    required this.sourceOfSupply,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.shipping,
    required this.adjustment,
    required this.total,
    required this.balance,
    required this.items,
  });
}

class VendorCreditItem {
  final String name;
  final String description;
  final double quantity;
  final double rate;
  final String taxRate;
  final double amount;

  const VendorCreditItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.taxRate,
    required this.amount,
  });
}

// Per-vendor-credit detail mock provider
final vendorCreditDetailProvider = Provider.family<VendorCreditDetail, String>((
  ref,
  id,
) {
  final cleanId = id.contains('VC-') ? id : 'VC-00001';
  if (cleanId == 'VC-00002') {
    return VendorCreditDetail(
      id: 'VC-00002',
      creditNoteNumber: 'VC-00002',
      referenceNumber: 'REF-2026-050',
      date: DateTime(2026, 4, 22),
      vendorName: 'ACME SUPPLIES',
      billingAddress:
          '45, Industrial Area, Sector 4\nBengaluru, Karnataka - 560001\nGSTIN: 29AABCA9876E1Z2',
      sourceOfSupply: '[KA] - Karnataka',
      destinationOfSupply: '[KL] - Kerala', // Interstate
      status: 'Closed',
      subtotal: 10550.85,
      taxAmount: 1899.15,
      shipping: 0.00,
      adjustment: 0.00,
      total: 12450.00,
      balance: 0.00,
      items: const [
        VendorCreditItem(
          name: 'Office Chairs',
          description: 'Ergonomic mesh office chair with lumbar support',
          quantity: 3,
          rate: 3000.00,
          taxRate: '18% GST',
          amount: 9000.00,
        ),
        VendorCreditItem(
          name: 'Desk Organizer',
          description: 'Wooden multi-compartment organizer',
          quantity: 5,
          rate: 310.17,
          taxRate: '18% GST',
          amount: 1550.85,
        ),
      ],
    );
  } else if (cleanId == 'VC-00003') {
    return VendorCreditDetail(
      id: 'VC-00003',
      creditNoteNumber: 'VC-00003',
      referenceNumber: 'REF-2026-051',
      date: DateTime(2026, 4, 25),
      vendorName: 'GLOBAL IMAGING',
      billingAddress:
          'Flat 102, Skyline Towers\nChennai, Tamil Nadu - 600002\nGSTIN: 33AAACG4321F2Z9',
      sourceOfSupply: '[TN] - Tamil Nadu',
      destinationOfSupply: '[KL] - Kerala', // Interstate
      status: 'Void',
      subtotal: 1949.15,
      taxAmount: 350.85,
      shipping: 0.00,
      adjustment: 0.00,
      total: 2300.00,
      balance: 0.00,
      items: const [
        VendorCreditItem(
          name: 'Ink Cartridge HP 680',
          description: 'HP 680 Black Original Ink Advantage Cartridge',
          quantity: 2,
          rate: 974.58,
          taxRate: '18% GST',
          amount: 1949.15,
        ),
      ],
    );
  } else if (cleanId == 'VC-00004') {
    return VendorCreditDetail(
      id: 'VC-00004',
      creditNoteNumber: 'VC-00004',
      referenceNumber: 'REF-2026-052',
      date: DateTime(2026, 4, 28),
      vendorName: 'TECH DISTRIBUTORS',
      billingAddress:
          'Shop 12, Electronics Plaza\nKochi, Kerala - 682025\nGSTIN: 32AABBD4321C1Z4',
      sourceOfSupply: '[KL] - Kerala',
      destinationOfSupply: '[KL] - Kerala',
      status: 'Draft',
      subtotal: 8305.08,
      taxAmount: 1494.92,
      shipping: 0.00,
      adjustment: 0.00,
      total: 9800.00,
      balance: 9800.00,
      items: const [
        VendorCreditItem(
          name: 'Wireless Router AC1200',
          description: 'Dual-band Gigabit wireless router',
          quantity: 4,
          rate: 2076.27,
          taxRate: '18% GST',
          amount: 8305.08,
        ),
      ],
    );
  }

  // Default to VC-00001
  return VendorCreditDetail(
    id: 'VC-00001',
    creditNoteNumber: 'VC-00001',
    referenceNumber: 'REF-2026-049',
    date: DateTime(2026, 4, 20),
    vendorName: 'ZERPAI TESTING',
    billingAddress:
        '32/4, MG Road, Landmark Building\nKochi, Kerala - 682016\nGSTIN: 32AABBC1234D1Z5',
    sourceOfSupply: '[KL] - Kerala',
    destinationOfSupply: '[KL] - Kerala',
    status: 'Open',
    subtotal: 4100.00,
    taxAmount: 738.00,
    shipping: 0.00,
    adjustment: 0.00,
    total: 4838.00,
    balance: 4838.00,
    items: const [
      VendorCreditItem(
        name: 'Computer Keyboard',
        description: 'Standard USB mechanical keyboard (QWERTY layout)',
        quantity: 2,
        rate: 800.00,
        taxRate: '18% GST',
        amount: 1600.00,
      ),
      VendorCreditItem(
        name: 'USB Optical Mouse',
        description: 'High-precision optical wired mouse',
        quantity: 10,
        rate: 250.00,
        taxRate: '18% GST',
        amount: 2500.00,
      ),
    ],
  );
});

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

  @override
  Widget build(BuildContext context) {
    final creditNote = ref.watch(
      vendorCreditDetailProvider(widget.vendorCreditId),
    );
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

  const _ActionBar({
    required this.creditNote,
    required this.onDelete,
    required this.onJournal,
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
            onPressed: () => context.push(
              AppRoutes.vendorCreditsCreate,
              extra: creditNote.id,
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
                onPressed: () {},
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
                onPressed: () {},
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
          MenuAnchor(
            builder: (ctx, ctrl, _) => IconButton(
              icon: const Icon(
                LucideIcons.moreHorizontal,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
              padding: EdgeInsets.zero,
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.bookOpen,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onJournal,
                child: const SizedBox(
                  width: 150,
                  child: Text(
                    'Journal',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ),
              ),
              MenuItemButton(
                leadingIcon: const Icon(
                  LucideIcons.trash2,
                  size: 14,
                  color: AppTheme.errorRed,
                ),
                onPressed: onDelete,
                child: const SizedBox(
                  width: 150,
                  child: Text(
                    'Delete',
                    style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
                  ),
                ),
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
        value: 'Approved',
        color: AppTheme.successGreen,
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
  final String billNumber;
  final String billDate;
  final String location;
  final double billAmount;
  final double billBalance;
  final String creditsAppliedOn;
  final TextEditingController creditsToApplyController;

  _ApplyBillRow({
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
  late final List<_ApplyBillRow> _bills;
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _bills = [
      _ApplyBillRow(
        billNumber: '11111',
        billDate: '05-05-2026',
        location: 'ZABNIX PRIVATE LIMITED',
        billAmount: 185.00,
        billBalance: 185.00,
        creditsAppliedOn: _dateFmt.format(DateTime.now()),
      ),
    ];
    for (final b in _bills) {
      b.creditsToApplyController.addListener(() => setState(() {}));
    }
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

  @override
  Widget build(BuildContext context) {
    final availableCredits = widget.creditNote.balance;
    final availableDateStr = _dateFmt.format(widget.creditNote.date);

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, minWidth: 700),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                  ClipRRect(
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

            const Divider(height: 1, color: AppTheme.borderLight),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    child: const Text('Save'),
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

class _JournalSection extends StatelessWidget {
  final VendorCreditDetail creditNote;

  const _JournalSection({required this.creditNote});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final entries = _journalEntries(creditNote, fmt);

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
                const Icon(
                  LucideIcons.bookOpen,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Journal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  creditNote.creditNoteNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            color: AppTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'Debit',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'Credit',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Rows
          ...entries.map((e) => _JournalRow(entry: e, fmt: fmt)),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Totals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    fmt.format(entries.fold(0.0, (s, e) => s + e.debit)),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    fmt.format(entries.fold(0.0, (s, e) => s + e.credit)),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
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

  List<_JournalEntry> _journalEntries(VendorCreditDetail c, NumberFormat fmt) {
    return [
      _JournalEntry(account: 'Accounts Payable', debit: 0, credit: c.total),
      _JournalEntry(
        account: 'Purchase Returns & Allowances',
        debit: c.subtotal,
        credit: 0,
      ),
      if (c.taxAmount > 0)
        _JournalEntry(
          account: 'Input Tax Credit (GST)',
          debit: c.taxAmount,
          credit: 0,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              entry.account,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              entry.debit > 0 ? fmt.format(entry.debit) : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              entry.credit > 0 ? fmt.format(entry.credit) : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
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
