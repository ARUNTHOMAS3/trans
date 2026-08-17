import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/models/vendor_credit_models.dart';

final vendorCreditDetailProvider =
    FutureProvider.family<VendorCreditDetail?, String>((ref, id) async {
      final supabase = Supabase.instance.client;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(id);

      List<dynamic> vendorCreditRows = [];
      if (isUuid) {
        vendorCreditRows = await supabase
            .from('vendor_credits')
            .select(
              'id, vendor_id, vendor_credit_number, vendor_credit_date, '
              'status, total_amount, subtotal, tax_amount, bill_id, reference_number',
            )
            .eq('id', id)
            .limit(1);
      } else {
        vendorCreditRows = await supabase
            .from('vendor_credits')
            .select(
              'id, vendor_id, vendor_credit_number, vendor_credit_date, '
              'status, total_amount, subtotal, tax_amount, bill_id, reference_number',
            )
            .eq('vendor_credit_number', id)
            .limit(1);
      }

      if (vendorCreditRows.isEmpty) {
        return null;
      }

      final vendorCreditRow = Map<String, dynamic>.from(
        vendorCreditRows.first as Map,
      );
      final vcId = vendorCreditRow['id']?.toString() ?? '';
      final vendorId = vendorCreditRow['vendor_id']?.toString() ?? '';
      String vendorName = 'Vendor';
      if (vendorId.isNotEmpty) {
        try {
          final vendorRows = await supabase
              .from('vendors')
              .select('id, display_name, company_name')
              .eq('id', vendorId)
              .limit(1);
          if (vendorRows.isNotEmpty) {
            final vendorRow = Map<String, dynamic>.from(vendorRows.first as Map);
            vendorName =
                vendorRow['display_name']?.toString().trim().isNotEmpty == true
                ? vendorRow['display_name'].toString().trim()
                : vendorRow['company_name']?.toString().trim().isNotEmpty == true
                ? vendorRow['company_name'].toString().trim()
                : vendorName;
          }
        } catch (_) {}
      }

      final billId = vendorCreditRow['bill_id']?.toString();
      String? appliedBillNumber;
      DateTime? appliedBillDate;
      double? appliedBillAmount;

      try {
        final applyLogs = await supabase
            .from('audit_logs')
            .select('new_values, created_at')
            .eq('table_name', 'vendor_credits')
            .eq('record_id', vcId)
            .eq('action', 'APPLY_TO_BILL')
            .order('created_at', ascending: false)
            .limit(1);
        if (applyLogs.isNotEmpty) {
          final logRow = Map<String, dynamic>.from(applyLogs.first as Map);
          final newValues = logRow['new_values'];
          if (newValues is Map) {
            appliedBillNumber =
                newValues['bill_number']?.toString().trim().isNotEmpty == true
                ? newValues['bill_number'].toString().trim()
                : appliedBillNumber;
            appliedBillDate = DateTime.tryParse(
              newValues['applied_on']?.toString() ?? '',
            );
            appliedBillAmount = double.tryParse(
              newValues['amount_credited']?.toString() ?? '',
            );
          }
          appliedBillDate ??= DateTime.tryParse(
            logRow['created_at']?.toString() ?? '',
          );
        }
      } catch (_) {}

      List<VendorCreditItem> itemsList = [];
      double calculatedSubtotal = 0;
      double calculatedTax = 0;

      if (vcId.isNotEmpty) {
        try {
          final itemRows = await supabase
              .from('vendor_credit_items')
              .select(
                'id, product_id, account_id, quantity, rate, discount_percent, '
                'discount_amount, tax_amount, line_total, remarks',
              )
              .eq('vendor_credit_id', vcId);

          for (final row in itemRows as List) {
            final r = Map<String, dynamic>.from(row as Map);
            final productId = r['product_id']?.toString() ?? '';
            String pName = r['remarks']?.toString().trim() ?? '';

            if (productId.isNotEmpty) {
              try {
                final pRes = await supabase
                    .from('products')
                    .select('product_name, billing_name, item_code')
                    .eq('id', productId)
                    .maybeSingle();
                if (pRes != null) {
                  final resolvedName =
                      (pRes['product_name'] ?? pRes['billing_name'])
                          ?.toString()
                          .trim() ??
                      '';
                  if (resolvedName.isNotEmpty) {
                    pName = resolvedName;
                  }
                }
              } catch (_) {}
            }

            if (pName.isEmpty) {
              pName = 'Item';
            }

            final qty = double.tryParse(r['quantity']?.toString() ?? '0') ?? 0.0;
            final rate = double.tryParse(r['rate']?.toString() ?? '0') ?? 0.0;
            final lineTotal =
                double.tryParse(r['line_total']?.toString() ?? '0') ?? (qty * rate);
            final lineTax =
                double.tryParse(r['tax_amount']?.toString() ?? '0') ?? 0.0;

            calculatedSubtotal += lineTotal;
            calculatedTax += lineTax;

            itemsList.add(
              VendorCreditItem(
                id: r['id']?.toString() ?? '',
                name: pName,
                description: r['remarks']?.toString() ?? '',
                quantity: qty,
                rate: rate,
                taxRate: lineTax > 0
                    ? '${((lineTax / (lineTotal > 0 ? lineTotal : 1)) * 100).toStringAsFixed(0)}%'
                    : '0%',
                amount: lineTotal,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error loading vendor credit items: $e');
        }
      }

      final total = double.tryParse(
            vendorCreditRow['total_amount']?.toString() ?? '0',
          ) ??
          (calculatedSubtotal + calculatedTax);

      final dbSubtotal = double.tryParse(vendorCreditRow['subtotal']?.toString() ?? '');
      final dbTax = double.tryParse(vendorCreditRow['tax_amount']?.toString() ?? '');

      final finalSubtotal = dbSubtotal ?? (calculatedSubtotal > 0 ? calculatedSubtotal : total);
      final finalTax = dbTax ?? (calculatedTax > 0 ? calculatedTax : (total - finalSubtotal > 0 ? total - finalSubtotal : 0.0));

      final creditDate = DateTime.tryParse(
        vendorCreditRow['vendor_credit_date']?.toString() ?? '',
      );

      return VendorCreditDetail(
        id: vcId.isNotEmpty ? vcId : id,
        creditNoteNumber:
            vendorCreditRow['vendor_credit_number']?.toString() ?? id,
        billId: billId,
        appliedBillNumber: appliedBillNumber,
        appliedBillDate: appliedBillDate,
        appliedBillAmount: appliedBillAmount,
        vendorName: vendorName,
        referenceNumber: vendorCreditRow['reference_number']?.toString() ?? '',
        date: creditDate ?? DateTime.now(),
        status: vendorCreditRow['status']?.toString() ?? 'draft',
        subtotal: finalSubtotal,
        taxAmount: finalTax > 0 ? finalTax : 0.0,
        total: total,
        balance: total,
        items: itemsList.isNotEmpty
            ? itemsList
            : [
                VendorCreditItem(
                  id: '1',
                  name: 'Item',
                  quantity: 1,
                  rate: finalSubtotal,
                  taxRate: '0%',
                  amount: finalSubtotal,
                ),
              ],
      );
    });
