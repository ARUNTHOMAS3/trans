import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_normalizer.dart';
import 'package:zerpai_erp/core/workflow/transaction_statuses.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/providers/inventory_adjustments_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';

class InventoryAdjustmentsDetailPanel extends ConsumerStatefulWidget {
  final InventoryAdjustment adjustment;
  final VoidCallback onClose;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final bool isBusy;

  const InventoryAdjustmentsDetailPanel({
    super.key,
    required this.adjustment,
    required this.onClose,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.isBusy = false,
  });

  @override
  ConsumerState<InventoryAdjustmentsDetailPanel> createState() =>
      _InventoryAdjustmentsDetailPanelState();
}

class _InventoryAdjustmentsDetailPanelState
    extends ConsumerState<InventoryAdjustmentsDetailPanel> {
  bool _isMutating = false;
  bool _showPdfView = false;
  final Set<String> _expandedBatchItems = {};

  InventoryAdjustment get adj => widget.adjustment;

  Future<void> _delete() async {
    setState(() => _isMutating = true);
    try {
      await ref.read(inventoryAdjustmentsActionsProvider).delete(adj.id);
      if (mounted) {
        ZerpaiToast.deleted(context, 'Adjustment');
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, ErrorHandler.getFriendlyMessage(e));
      }
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          padding: const EdgeInsets.only(left: 24, right: 16),
          child: Row(
            children: [
              const Text(
                'Adjustment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              _iconChip(LucideIcons.paperclip),
              const SizedBox(width: 8),
              _iconChip(LucideIcons.messageSquare),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onClose,
                tooltip: 'Close',
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppTheme.errorRed,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.only(left: 24, right: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              _actionBtn(
                icon: LucideIcons.pencil,
                label: 'Edit',
                iconColor: AppTheme.primaryBlue,
                textColor: AppTheme.primaryBlue,
                textWeight: FontWeight.w600,
                onTap: _isMutating
                    ? null
                    : () {
                        final orgId =
                            GoRouterState.of(
                              context,
                            ).pathParameters['orgSystemId'] ??
                            '';
                        context.go(
                          '/$orgId/inventory/adjustments/edit/${adj.id}?from=inventory_adjustments&returnAdjustmentId=${adj.id}',
                          extra: <String, dynamic>{'initialAdjustment': adj},
                        );
                      },
              ),
              _divider(),
              PopupMenuButton<String>(
                tooltip: 'PDF/Print',
                offset: const Offset(0, 34),
                color: Colors.white,
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(value: 'pdf', child: Text('PDF')),
                ],
                onSelected: (value) {
                  if (value == 'pdf') {
                    setState(() => _showPdfView = true);
                  }
                },
                child: _actionBtn(
                  icon: LucideIcons.fileText,
                  label: 'PDF/Print',
                  iconColor: AppTheme.textSecondary,
                  textColor: const Color(0xFF495057),
                  textWeight: FontWeight.w400,
                  onTap: null,
                ),
              ),
              _divider(),
              _buildMoreMenu(context),
              const Spacer(),
              if (_isMutating || widget.isBusy)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconChip(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: AppTheme.textSecondary),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    Color iconColor = AppTheme.textSecondary,
    Color textColor = AppTheme.textSecondary,
    FontWeight textWeight = FontWeight.w400,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 32,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: const Color(0x0D000000),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCED4DA)),
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: textWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const VerticalDivider(
    width: 24,
    indent: 14,
    endIndent: 14,
    color: AppTheme.borderColor,
  );

  Widget _buildMoreMenu(BuildContext context) {
    final menuItemStyle = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      minimumSize: WidgetStateProperty.all(const Size(132, 38)),
      alignment: Alignment.centerLeft,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppTheme.infoBlue;
        }
        return Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        return AppTheme.textPrimary;
      }),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );

    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(10),
        minimumSize: WidgetStatePropertyAll(Size(146, 0)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          style: menuItemStyle,
          onPressed: () {
            final orgId =
                GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
            context.go(
              '/$orgId/inventory/adjustments/create?clone=true&adjustmentId=${adj.id}&from=inventory_adjustments&returnAdjustmentId=${adj.id}',
              extra: <String, dynamic>{
                'initialAdjustment': adj,
                'isClone': true,
              },
            );
          },
          child: const Text('Clone'),
        ),
        MenuItemButton(
          style: menuItemStyle,
          onPressed: _delete,
          child: const Text('Delete'),
        ),
      ],
      builder: (context, controller, child) {
        return SizedBox(
          width: 32,
          height: 32,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            hoverColor: const Color(0x0D000000),
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCED4DA)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                LucideIcons.moreVertical,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd-MM-yyyy');
    final timeFmt = DateFormat('dd-MM-yyyy hh:mm a');
    final effectiveTotal = _effectiveTotal();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _userAuditStrip(),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Show PDF View',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPdfToggle(),
                ],
              ),
              const SizedBox(height: 14),
              _buildAdjustmentDocument(
                currencyFmt,
                dateFmt,
                timeFmt,
                effectiveTotal,
                _showPdfView,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfToggle() {
    return SizedBox(
      height: 24,
      child: Switch(
        value: _showPdfView,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeTrackColor: const Color(0xFF2C86E6),
        inactiveTrackColor: const Color(0xFFD2D4D8),
        activeThumbColor: Colors.white,
        inactiveThumbColor: Colors.white,
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2C86E6);
          }
          return const Color(0xFFD2D4D8);
        }),
        trackOutlineWidth: const WidgetStatePropertyAll(1.0),
        onChanged: (v) => setState(() => _showPdfView = v),
      ),
    );
  }

  Widget _buildAdjustmentDocument(
    NumberFormat currencyFmt,
    DateFormat dateFmt,
    DateFormat timeFmt,
    double effectiveTotal,
    bool showRibbon,
  ) {
    final isPdfView = showRibbon;
    if (isPdfView) {
      return _buildPdfDocument(currencyFmt, dateFmt, timeFmt, effectiveTotal);
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                          _infoRow('Date', dateFmt.format(adj.adjustmentDate)),
                          _infoRow('Reason', _toLabel(adj.reason)),
                          _infoRow(
                            'Status',
                            _statusLabel(adj.status),
                            isStatus: true,
                          ),
                          _infoRow(
                            'Account',
                            (adj.accountName ?? '').isNotEmpty
                                ? adj.accountName!
                                : 'Cost of Goods Sold',
                          ),
                          _infoRow(
                            'Adjustment Type',
                            _toLabel(adj.adjustmentType),
                          ),
                          if ((adj.warehouseName ?? '').isNotEmpty)
                            _infoRow('Location Name', adj.warehouseName!),
                          _infoRow('Adjusted By', _actorLabel()),
                          _infoRow(
                            'Created Time',
                            timeFmt.format(adj.createdAt.toLocal()),
                          ),
                          if ((adj.notes ?? '').trim().isNotEmpty)
                            _infoRow('Description', adj.notes!.trim()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _totalCard(currencyFmt.format(effectiveTotal)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 18),
                _buildAdjustedItemsSection(currencyFmt),
                _buildBatchesSection(adj.items),
                _buildBinsSection(adj.items),
                const SizedBox(height: 12),
                _buildJournalOverviewSection(currencyFmt, effectiveTotal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfDocument(
    NumberFormat currencyFmt,
    DateFormat dateFmt,
    DateFormat timeFmt,
    double effectiveTotal,
  ) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 760,
                constraints: const BoxConstraints(minHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(48, 64, 48, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text(
                              'INVENTORY ADJUSTMENT',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 255,
                              child: Column(
                                children: [
                                  _pdfMetaRow(
                                    'Date',
                                    dateFmt.format(adj.adjustmentDate),
                                  ),
                                  _pdfMetaRow('Reason', _toLabel(adj.reason)),
                                  _pdfMetaRow(
                                    'Account',
                                    (adj.accountName ?? '').isNotEmpty
                                        ? adj.accountName!
                                        : 'Cost of Goods Sold',
                                  ),
                                  _pdfMetaRow(
                                    'Adjustment Type',
                                    _toLabel(adj.adjustmentType),
                                  ),
                                  _pdfMetaRow(
                                    'Location Name',
                                    (adj.warehouseName ?? '').isNotEmpty
                                        ? adj.warehouseName!
                                        : '-',
                                  ),
                                  _pdfMetaRow('Created By', _actorLabel()),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPdfItemsTable(currencyFmt, effectiveTotal),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _PdfCornerRibbon(
                        label: _statusLabel(adj.status),
                        color: _ribbonColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBatchesSection(adj.items),
            const SizedBox(height: 12),
            _buildJournalOverviewSection(currencyFmt, effectiveTotal),
          ],
        ),
      ),
    );
  }

  Widget _pdfMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF222222),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfItemsTable(NumberFormat currencyFmt, double effectiveTotal) {
    final pdfItems = adj.items;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD6D8DE)),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF2F3338),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Item & Description',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Quantity Adjusted',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Cost Price',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (pdfItems.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No adjusted items found.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            ...List<Widget>.generate(pdfItems.length, (index) {
              final item = pdfItems[index];
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFD6D8DE))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        _displayItemLabel(item),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantityAdjusted.toStringAsFixed(2)}\npcs',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        currencyFmt.format(item.costPrice),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                const Spacer(),
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 24),
                Text(
                  currencyFmt.format(effectiveTotal),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _ribbonColor() {
    switch (normalizeTransactionStatus(adj.status)) {
      case TransactionStatuses.approved:
        return const Color(0xFF0D6EFD);
      case TransactionStatuses.pendingApproval:
        return const Color(0xFFF4A100);
      case TransactionStatuses.rejected:
        return AppTheme.errorRed;
      case TransactionStatuses.cancelled:
        return AppTheme.textSecondary;
      default:
        return const Color(0xFF90A4AE);
    }
  }

  Widget _userAuditStrip() {
    Widget person(
      String title,
      String name, {
      required String tooltipMessage,
      VoidCallback? onTap,
    }) {
      final normalized = name.trim();
      final showChip = normalized.isNotEmpty && normalized != '-';
      final initials = showChip ? normalized[0].toUpperCase() : '';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          if (showChip)
            ZTooltip(
              message: tooltipMessage,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDADDE3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        normalized,
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
            )
          else
            const Text(
              '-',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      );
    }

    final actor = _actorLabel();
    final approver = _approverLabel();
    final submittedBy = _actorLabelWithEmail();
    final approvedBy = _approverLabelWithEmail();
    final submittedAt = DateFormat('dd-MM-yyyy').format(adj.createdAt);
    final approvedAt = adj.approvedAt != null
        ? DateFormat('dd-MM-yyyy').format(adj.approvedAt!)
        : submittedAt;
    final statusLabel =
        normalizeTransactionStatus(adj.status) == TransactionStatuses.approved
        ? 'Approved'
        : _statusLabel(adj.status);

    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        person(
          'Submitted by',
          actor,
          tooltipMessage: '$submittedBy\nSubmitted on: $submittedAt',
          onTap: _showApprovalDetailsSidebar,
        ),
        person(
          'Approved by',
          approver,
          tooltipMessage: '$approvedBy\n$statusLabel on: $approvedAt',
          onTap: _showApprovalDetailsSidebar,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showApprovalDetailsSidebar,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'View Approval Details',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0x33000000),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showApprovalDetailsSidebar() async {
    final submittedBy = _actorLabelWithEmail();
    final approvedBy = _approverLabelWithEmail();
    final submittedAt = DateFormat('dd-MM-yyyy').format(adj.createdAt);
    final approvedAt = adj.approvedAt != null
        ? DateFormat('dd-MM-yyyy').format(adj.approvedAt!)
        : submittedAt;
    final isApproved =
        normalizeTransactionStatus(adj.status) == TransactionStatuses.approved;
    final statusLabel = isApproved ? 'APPROVED' : _statusLabel(adj.status);
    final actorWithEmailPattern = RegExp(r'^(.*)\s\(([^()]+@[^()]+)\)$');
    final approvedMatch = actorWithEmailPattern.firstMatch(approvedBy.trim());
    final approvedName = approvedMatch?.group(1)?.trim() ?? approvedBy;
    final approvedEmail = approvedMatch?.group(2)?.trim();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      barrierLabel: 'Approval details',
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: Material(
              color: Colors.white,
              elevation: 8,
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 10, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Approval Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryBlue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Submitter Details',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            submittedAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Text(
                        submittedBy,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0F2F5),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.user,
                                    color: AppTheme.textSecondary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF20B26B),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 1,
                                    margin: const EdgeInsets.only(top: 6),
                                    color: const Color(0xFFE3E6EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: statusLabel,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF20B26B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' | ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: approvedAt,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    approvedName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (approvedEmail != null &&
                                      approvedEmail.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      approvedEmail,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w400,
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _totalCard(String totalValue) {
    return Container(
      width: 255,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 4),
              Icon(LucideIcons.info, size: 14, color: AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            totalValue,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? _statusBadge(adj.status)
                : Text(
                    value.isEmpty ? '-' : value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: const BoxDecoration(color: Color(0xFF2C86E6)),
        child: Text(
          _statusLabel(status),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (normalizeTransactionStatus(status)) {
      case TransactionStatuses.approved:
        return 'ADJUSTED';
      case TransactionStatuses.pendingApproval:
        return 'SUBMITTED';
      case TransactionStatuses.rejected:
        return 'REJECTED';
      case TransactionStatuses.cancelled:
        return 'CANCELLED';
      default:
        return 'DRAFT';
    }
  }

  Widget _buildAdjustedItemsSection(NumberFormat currencyFmt) {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
      letterSpacing: 0.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Adjusted Items',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Item Details',
                        style: headerStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Quantity Adjusted',
                        style: headerStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Cost Price',
                        style: headerStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Rows
              if (adj.items.isNotEmpty)
                ...adj.items.map((item) => _itemRow(item, currencyFmt))
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No adjusted items found.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
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

  Widget _itemRow(InventoryAdjustmentItem item, NumberFormat currencyFmt) {
    final label = _displayItemLabel(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                    color: Colors.white,
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openItemTransactions(
                      _resolveProductIdForNavigation(item),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0x22000000),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${item.quantityAdjusted.toStringAsFixed(2)} (pcs)',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              currencyFmt.format(item.costPrice),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesSection(List<InventoryAdjustmentItem> items) {
    final itemsWithBatches = items.where((i) {
      return i.batchAllocations.isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Batches',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: itemsWithBatches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(
                    'No batch data available for this adjustment.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: itemsWithBatches
                      .map((item) => _batchItemSection(item))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildBinsSection(List<InventoryAdjustmentItem> items) {
    final binGroups = <_BinGroup>[];
    for (final item in items) {
      for (final batch in item.batchAllocations) {
        final binCode = (batch.binCode ?? '').trim();
        final binId = (batch.binId ?? '').trim();
        final binLabel = binCode.isNotEmpty
            ? binCode
            : (binId.isNotEmpty && !_isUuid(binId) ? binId : '');
        if (binLabel.isEmpty) continue;
        final qty = batch.quantityIn != 0
            ? batch.quantityIn.abs()
            : batch.quantityOut.abs();
        binGroups.add(
          _BinGroup(
            itemLabel: _displayItemLabel(item),
            batchLabel: _displayBatchLabel(batch),
            binLabel: binLabel,
            quantity: qty,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Bins',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: binGroups.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(
                    'No bin data available for this adjustment.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ITEM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'BATCH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'BIN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'QUANTITY IN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...binGroups.map(
                      (group) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                group.itemLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                group.batchLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                group.binLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${group.quantity.toStringAsFixed(0)} pcs',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
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
    );
  }

  Widget _buildJournalOverviewSection(
    NumberFormat currencyFmt,
    double effectiveTotal,
  ) {
    final accountName = (adj.accountName ?? '').trim().isNotEmpty
        ? adj.accountName!.trim()
        : 'Cost of Goods Sold';
    final location = (adj.warehouseName ?? '').trim().isNotEmpty
        ? adj.warehouseName!.trim()
        : '-';
    final signedBasis = adj.adjustmentType.toLowerCase().contains('value')
        ? adj.adjustmentValue
        : adj.quantityAdjusted;
    final isIncrease = signedBasis >= 0;
    final amount = effectiveTotal.abs();
    final journalTitle = adj.adjustmentType.toLowerCase().contains('value')
        ? 'Inventory Adjustment By Value'
        : 'Inventory Adjustment By Quantity';

    final normalizedAccountRows = adj.accountEntries
        .where((entry) => entry.accountId.trim().isNotEmpty)
        .map(
          (entry) => _JournalRow(
            account: (entry.accountName ?? '').trim().isNotEmpty
                ? entry.accountName!.trim()
                : accountName,
            location: location,
            debit: entry.debit,
            credit: entry.credit,
          ),
        )
        .toList();

    final rows = normalizedAccountRows.isNotEmpty
        ? normalizedAccountRows
        : <_JournalRow>[
            _JournalRow(
              account: 'Inventory Asset',
              location: location,
              debit: isIncrease ? amount : 0.0,
              credit: isIncrease ? 0.0 : amount,
            ),
            _JournalRow(
              account: accountName,
              location: location,
              debit: isIncrease ? 0.0 : amount,
              credit: isIncrease ? amount : 0.0,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              'Journal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              'Amount is displayed in your base currency INR',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              journalTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'DEBIT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'CREDIT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.account,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.debit == 0 ? '0.00' : currencyFmt.format(row.debit),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.credit == 0
                            ? '0.00'
                            : currencyFmt.format(row.credit),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Spacer(flex: 6),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyFmt.format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyFmt.format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
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

  Widget _batchItemSection(InventoryAdjustmentItem item) {
    final productName = _displayItemLabel(item);
    final realBatches = item.batchAllocations;
    final batchCount = realBatches.length;
    final isExpanded = _expandedBatchItems.contains(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedBatchItems.remove(item.id);
            } else {
              _expandedBatchItems.add(item.id);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openItemTransactions(
                      _resolveProductIdForNavigation(item),
                    ),
                    child: Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0x22000000),
                      ),
                    ),
                  ),
                ),
                Text(
                  '$batchCount ${batchCount == 1 ? 'Batch' : 'Batches'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'QUANTITY IN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...realBatches.map(
            (b) => InkWell(
              onTap: () => _openBatchDetailsSidebar(
                productName: productName,
                item: item,
                batch: b,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        _displayBatchLabel(b),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0x22000000),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${b.quantityIn.toStringAsFixed(0)} pcs',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _resolveProductIdForNavigation(InventoryAdjustmentItem item) {
    final itemProductId = item.productId.trim();
    if (itemProductId.isNotEmpty && _isUuid(itemProductId)) {
      return itemProductId;
    }
    final headerProductId = adj.productId.trim();
    if (headerProductId.isNotEmpty && _isUuid(headerProductId)) {
      return headerProductId;
    }
    return itemProductId.isNotEmpty ? itemProductId : headerProductId;
  }

  void _openItemTransactions(String itemId) {
    if (itemId.trim().isEmpty) return;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    final targetPath =
        '/$orgSystemId/items/detail/$itemId?tab=transactions&transactionType=inventoryAdjustments';
    if (kIsWeb) {
      web.window.open(targetPath, '_blank');
      return;
    }
    context.go(targetPath);
  }

  Future<void> _openBatchDetailsSidebar({
    required String productName,
    required InventoryAdjustmentItem item,
    required InventoryAdjustmentBatchAllocation batch,
  }) async {
    final batchRef = _displayBatchLabel(batch);
    final transactions = _buildBatchTransactions(item, batch);
    final inTransactions = transactions
        .where((tx) => tx.isInTransaction)
        .toList();
    final outTransactions = transactions
        .where((tx) => !tx.isInTransaction)
        .toList();
    var showOutTransactions = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      barrierLabel: 'Batch details',
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  child: SizedBox(
                    width: 410,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: const Color(0xFFEAF0FB),
                          padding: const EdgeInsets.fromLTRB(16, 14, 6, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      batchRef,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Manufacturer Batch#: ${_displayManufacturerBatch(batch)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manufactured date: ${_formatBatchDate(batch.mfdDate)}  |  Expiry Date: ${_formatBatchDate(batch.expiryDate)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  LucideIcons.x,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _qtyInfo(
                                  'Quantity In',
                                  batch.quantityIn.toStringAsFixed(2),
                                ),
                              ),
                              Expanded(
                                child: _qtyInfo(
                                  'Quantity Available',
                                  (batch.quantityIn - batch.quantityOut)
                                      .toStringAsFixed(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _tabBtn(
                                  label: 'IN TRANSACTIONS',
                                  selected: !showOutTransactions,
                                  onTap: () => setLocalState(
                                    () => showOutTransactions = false,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _tabBtn(
                                  label: 'OUT TRANSACTIONS',
                                  selected: showOutTransactions,
                                  onTap: () => setLocalState(
                                    () => showOutTransactions = true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                            itemCount:
                                (showOutTransactions
                                        ? outTransactions
                                        : inTransactions)
                                    .length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 16,
                              color: AppTheme.borderColor,
                            ),
                            itemBuilder: (_, i) {
                              final tx = (showOutTransactions
                                  ? outTransactions
                                  : inTransactions)[i];
                              return _batchTxRow(tx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_BatchTransaction> _buildBatchTransactions(
    InventoryAdjustmentItem item,
    InventoryAdjustmentBatchAllocation batch,
  ) {
    final txDate = DateFormat('dd-MM-yyyy').format(adj.adjustmentDate);
    final txReference = _displayAdjustmentReference();
    final rows = <_BatchTransaction>[];
    if (batch.quantityIn > 0) {
      rows.add(
        _BatchTransaction(
          title: 'Inventory Adjustment By Quantity',
          reference: txReference,
          counterparty: _actorLabel(),
          quantity: batch.quantityIn.abs().toStringAsFixed(2),
          date: txDate,
          location: adj.warehouseName ?? 'Primary Warehouse',
          iconColor: const Color(0xFF7551D9),
          isInTransaction: true,
        ),
      );
    }
    if (batch.quantityOut > 0) {
      rows.add(
        _BatchTransaction(
          title: 'Inventory Adjustment By Quantity',
          reference: txReference,
          counterparty: _actorLabel(),
          quantity: batch.quantityOut.abs().toStringAsFixed(2),
          date: txDate,
          location: adj.warehouseName ?? 'Primary Warehouse',
          iconColor: const Color(0xFF7551D9),
          isInTransaction: false,
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        _BatchTransaction(
          title: 'Inventory Adjustment By Quantity',
          reference: txReference,
          counterparty: _actorLabel(),
          quantity: '0.00',
          date: txDate,
          location: adj.warehouseName ?? 'Primary Warehouse',
          iconColor: const Color(0xFF7551D9),
          isInTransaction: true,
        ),
      );
    }
    return rows;
  }

  Widget _qtyInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value pcs',
          style: const TextStyle(
            fontSize: 29,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _tabBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _batchTxRow(_BatchTransaction tx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [tx.iconColor.withValues(alpha: 0.75), tx.iconColor],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            LucideIcons.badgeCheck,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tx.title} : ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.reference,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tx.counterparty}  |  Qty: ${tx.quantity}  |  Date: ${tx.date}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.location,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _effectiveTotal() {
    final lineTotal = adj.items.fold<double>(
      0,
      (sum, item) => sum + (item.quantityAdjusted.abs() * item.costPrice),
    );
    if (adj.adjustmentValue != 0) return adj.adjustmentValue.abs();
    if (lineTotal != 0) return lineTotal;
    return (adj.quantityAdjusted.abs() * adj.costPrice);
  }

  String _actorLabel() {
    final preferred = (adj.adjustedByName ?? '').trim();
    if (preferred.isNotEmpty) return preferred;
    final fallback = (adj.adjustedBy ?? '').trim();
    if (fallback.isEmpty || _isUuid(fallback)) return '-';
    return fallback;
  }

  String _approverLabel() {
    final preferred = (adj.approvedByName ?? '').trim();
    if (preferred.isNotEmpty) return preferred;
    final fallback = (adj.approvedBy ?? '').trim();
    if (fallback.isEmpty || _isUuid(fallback)) {
      if (normalizeTransactionStatus(adj.status) ==
          TransactionStatuses.approved) {
        return _actorLabel();
      }
      return '-';
    }
    return fallback;
  }

  String _actorLabelWithEmail() {
    return _formatNameAndEmail(
      _actorLabel(),
      (adj.adjustedByEmail ?? '').trim(),
    );
  }

  String _approverLabelWithEmail() {
    final approver = _approverLabel();
    final approverEmail = (adj.approvedByEmail ?? '').trim();
    if (approver != '-' && approverEmail.isNotEmpty) {
      return _formatNameAndEmail(approver, approverEmail);
    }
    if (normalizeTransactionStatus(adj.status) ==
        TransactionStatuses.approved) {
      return _formatNameAndEmail(
        _actorLabel(),
        (adj.adjustedByEmail ?? '').trim(),
      );
    }
    return approver;
  }

  String _formatNameAndEmail(String name, String email) {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty || normalizedName == '-') return '-';
    if (normalizedEmail.isEmpty) return normalizedName;
    return '$normalizedName ($normalizedEmail)';
  }

  bool _isUuid(String v) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(v);

  String _toLabel(String value) {
    if (value.trim().isEmpty) return value;
    return value
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  String _displayPrimaryProductLabel() {
    final preferred = (adj.productName ?? '').trim();
    if (preferred.isNotEmpty) return preferred;
    final fallback = adj.productId.trim();
    if (fallback.isEmpty || _isUuid(fallback)) return 'Item';
    return fallback;
  }

  String _displayItemLabel(InventoryAdjustmentItem item) {
    final itemName = (item.productName ?? '').trim();
    if (itemName.isNotEmpty) return itemName;
    if ((adj.productName ?? '').trim().isNotEmpty &&
        (item.productId.trim().isEmpty || _isUuid(item.productId.trim()))) {
      return adj.productName!.trim();
    }
    if (item.productId == adj.productId) return _displayPrimaryProductLabel();
    final fallback = item.productId.trim();
    if (fallback.isEmpty || _isUuid(fallback)) return 'Item';
    return fallback;
  }

  String _displayBatchLabel(InventoryAdjustmentBatchAllocation batch) {
    final batchNo = (batch.batchNo ?? '').trim();
    if (batchNo.isNotEmpty && !_isUuid(batchNo)) return batchNo;
    final reference = (batch.batchReference ?? '').trim();
    if (reference.isNotEmpty && !_isUuid(reference)) return reference;
    final batchId = (batch.batchId ?? '').trim();
    if (batchId.isNotEmpty && !_isUuid(batchId)) return batchId;
    return 'Batch';
  }

  String _displayManufacturerBatch(InventoryAdjustmentBatchAllocation batch) {
    final manufacturerBatch = (batch.manufacturerBatchNumber ?? '').trim();
    if (manufacturerBatch.isNotEmpty && !_isUuid(manufacturerBatch)) {
      return manufacturerBatch;
    }
    final batchNo = (batch.batchNo ?? '').trim();
    if (batchNo.isNotEmpty && !_isUuid(batchNo)) return batchNo;
    final batchId = (batch.batchId ?? '').trim();
    if (batchId.isEmpty || _isUuid(batchId)) return '-';
    return batchId;
  }

  String _displayAdjustmentReference() {
    final reference = (adj.referenceNumber ?? '').trim();
    if (reference.isNotEmpty && !_isUuid(reference)) {
      return '#$reference';
    }
    return 'Inventory Adjustment';
  }

  String _formatBatchDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd-MM-yyyy').format(date.toLocal());
  }
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
            top: 24,
            left: -32,
            child: Transform.rotate(
              angle: -0.7853981633974483, // -pi/4
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
            top: 22,
            left: -34,
            child: Transform.rotate(
              angle: -0.7853981633974483, // -pi/4
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
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatchTransaction {
  final String title;
  final String reference;
  final String counterparty;
  final String quantity;
  final String date;
  final String location;
  final Color iconColor;
  final bool isInTransaction;

  const _BatchTransaction({
    required this.title,
    required this.reference,
    required this.counterparty,
    required this.quantity,
    required this.date,
    required this.location,
    required this.iconColor,
    required this.isInTransaction,
  });
}

class _JournalRow {
  final String account;
  final String location;
  final double debit;
  final double credit;

  const _JournalRow({
    required this.account,
    required this.location,
    required this.debit,
    required this.credit,
  });
}

class _BinGroup {
  final String itemLabel;
  final String batchLabel;
  final String binLabel;
  final double quantity;

  const _BinGroup({
    required this.itemLabel,
    required this.batchLabel,
    required this.binLabel,
    required this.quantity,
  });
}
