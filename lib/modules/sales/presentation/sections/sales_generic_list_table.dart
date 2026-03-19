part of '../sales_generic_list.dart';

extension _GenericListTable on _SalesGenericListScreenState {
  Widget _buildHeaderCell(ColumnDef col) {
    final width = _columnWidths[col.key] ?? 150.0;
    final isSorted = _sortColumn == col.key;
    final isHovered = _hoverColumn == col.key;

    return Stack(
      children: [
        MouseRegion(
          onEnter: (_) => _state(() => _hoverColumn = col.key),
          onExit: (_) => _state(() => _hoverColumn = null),
          child: InkWell(
            onTap: () => _onSort(col.key),
            child: Container(
              width: width,
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    col.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSorted
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  // Sort Icon - Show if sorted OR hovered
                  if (isHovered || isSorted)
                    Icon(
                      isSorted
                          ? (_isAscending
                                ? LucideIcons.arrowUp
                                : LucideIcons.arrowDown)
                          : LucideIcons.arrowUp,
                      size: 14,
                      color: isSorted
                          ? AppTheme.primaryBlueDark
                          : AppTheme.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                _onResize(col.key, details.delta.dx);
              },
              child: Container(
                width: 20,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 1,
                    height: 20,
                    color: AppTheme.borderColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCell(dynamic item, ColumnDef col) {
    final width = _columnWidths[col.key] ?? 150.0;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
        overflow: _clipText ? TextOverflow.clip : TextOverflow.ellipsis,
        maxLines: 1,
        child: _getCellContent(item, col.key),
      ),
    );
  }

  Widget _getCellContent(dynamic item, String key) {
    if (item is SalesCustomer) {
      if (key == 'name') {
        return Text(
          item.displayName,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      if (key == 'company_name') {
        return Text(
          item.companyName ?? '',
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'email') {
        return Text(item.email ?? '', style: const TextStyle(fontSize: 13));
      }
      if (key == 'phone') {
        return Text(item.phone ?? '', style: const TextStyle(fontSize: 13));
      }
      if (key == 'mobile_phone') {
        return Text(
          item.mobilePhone ?? '',
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'gst_treatment') {
        String t = 'Unregistered Business';
        if (item.customerType == 'Consumer') {
          t = 'Consumer';
        } else if (item.gstin != null && item.gstin!.isNotEmpty) {
          t = 'Registered Business - Regular';
        }
        return Text(t, style: const TextStyle(fontSize: 13));
      }
      if (key == 'gst_registration_number') {
        return Text(item.gstin ?? '', style: const TextStyle(fontSize: 13));
      }
      if (key == 'receivables_bcy' || key == 'receivables') {
        return Container(
          alignment: Alignment.centerLeft,
          child: Text(
            NumberFormat.currency(
              symbol: '₹',
              decimalDigits: 2,
            ).format(item.receivables ?? 0),
            style: const TextStyle(fontSize: 13),
          ),
        );
      }
      if (key == 'first_name') {
        return Text(item.firstName ?? '', style: const TextStyle(fontSize: 13));
      }
      if (key == 'last_name') {
        return Text(item.lastName ?? '', style: const TextStyle(fontSize: 13));
      }

      return const Text('-');
    } else if (item is SalesOrder) {
      if (key == 'Date') {
        return Text(
          DateFormat('dd MMM yyyy').format(item.saleDate),
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Order#') {
        return Text(
          item.saleNumber,
          style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlueDark),
        );
      }
      if (key == 'Customer Name') {
        return Text(
          item.customer?.displayName ?? 'N/A',
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Status') {
        return _statusBadge(item.status);
      }
      if (key == 'Amount') {
        return Text(
          NumberFormat.currency(symbol: '₹').format(item.total),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        );
      }
    } else if (item is SalesPayment) {
      if (key == 'Date') {
        return Text(
          DateFormat('dd MMM yyyy').format(item.paymentDate),
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Payment#') {
        return Text(
          item.paymentNumber,
          style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlueDark),
        );
      }
      if (key == 'Reference#') {
        return Text(item.reference ?? '', style: const TextStyle(fontSize: 13));
      }
      if (key == 'Customer Name') {
        return Text(
          item.customerName ?? 'N/A',
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Mode') {
        return Text(item.paymentMode, style: const TextStyle(fontSize: 13));
      }
      if (key == 'Amount') {
        return Text(
          NumberFormat.currency(symbol: '₹').format(item.amount),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        );
      }
    } else if (item is SalesEWayBill) {
      if (key == 'Date') {
        return Text(
          DateFormat('dd MMM yyyy').format(item.billDate),
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'E-Way Bill#') {
        return Text(
          item.billNumber,
          style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlueDark),
        );
      }
      if (key == 'Supply Type') {
        return Text(item.supplyType, style: const TextStyle(fontSize: 13));
      }
      if (key == 'Sub Type') {
        return Text(item.subType, style: const TextStyle(fontSize: 13));
      }
      if (key == 'Status') {
        return _statusBadge(item.status);
      }
    } else if (item is SalesPaymentLink) {
      if (key == 'Date') {
        return Text(
          DateFormat('dd MMM yyyy').format(item.expiryDate ?? DateTime.now()),
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Link#') {
        return Text(
          item.linkNumber,
          style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlueDark),
        );
      }
      if (key == 'Customer Name') {
        return Text(
          item.customer?['display_name'] ?? 'N/A',
          style: const TextStyle(fontSize: 13),
        );
      }
      if (key == 'Amount') {
        return Text(
          NumberFormat.currency(symbol: '₹').format(item.amount),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        );
      }
      if (key == 'Status') {
        return _statusBadge(item.status);
      }
    }

    // Fallback for non-mapped items (generic support)
    return Text(item.toString(), style: const TextStyle(fontSize: 13));
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status.toLowerCase() == 'draft') color = Colors.grey;
    if (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'paid') {
      color = Colors.green;
    }
    if (status.toLowerCase() == 'void') color = Colors.red;

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
