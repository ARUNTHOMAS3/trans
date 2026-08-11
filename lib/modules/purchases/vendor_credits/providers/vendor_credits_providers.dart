import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/models/vendor_credit_models.dart';

final vendorCreditDetailProvider =
    FutureProvider.family<VendorCreditDetail?, String>((ref, id) async {
      final supabase = Supabase.instance.client;
      final vendorCreditRows = await supabase
          .from('vendor_credits')
          .select(
            'id, vendor_id, vendor_credit_number, vendor_credit_date, '
            'status, total_amount, bill_id, reference_number',
          )
          .eq('vendor_credit_number', id)
          .limit(1);
      if (vendorCreditRows.isEmpty) {
        return null;
      }

      final vendorCreditRow = Map<String, dynamic>.from(
        vendorCreditRows.first as Map,
      );
      final vendorId = vendorCreditRow['vendor_id']?.toString() ?? '';
      String vendorName = 'Sample Vendor';
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
            .eq('record_id', vendorCreditRow['id']?.toString() ?? '')
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

      final total = double.tryParse(
            vendorCreditRow['total_amount']?.toString() ?? '0',
          ) ??
          0;
      final creditDate = DateTime.tryParse(
        vendorCreditRow['vendor_credit_date']?.toString() ?? '',
      );

      return VendorCreditDetail(
        id: vendorCreditRow['id']?.toString() ?? id,
        creditNoteNumber:
            vendorCreditRow['vendor_credit_number']?.toString() ?? id,
        billId: billId,
        appliedBillNumber: appliedBillNumber,
        appliedBillDate: appliedBillDate,
        appliedBillAmount: appliedBillAmount,
        vendorName: vendorName,
        referenceNumber: vendorCreditRow['reference_number']?.toString() ?? '',
        date: creditDate ?? DateTime(2026, 7, 17),
        status: vendorCreditRow['status']?.toString() ?? 'draft',
        subtotal: total > 0 ? total / 1.18 : 1000,
        taxAmount: total > 0 ? total - (total / 1.18) : 180,
        total: total > 0 ? total : 1180,
        balance: total > 0 ? total : 1180,
        items: [
          VendorCreditItem(
            id: '1',
            name: 'Sample Item',
            quantity: 1,
            rate: 1000,
            taxRate: '18%',
            amount: 1000,
          ),
        ],
      );
    });
