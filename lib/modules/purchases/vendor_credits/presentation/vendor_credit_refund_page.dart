import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_report.dart';

class VendorCreditRefundPage extends ConsumerWidget {
  final String vendorCreditId;
  const VendorCreditRefundPage({super.key, required this.vendorCreditId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VendorCreditsOverviewPage(
      initialCreditNoteNumber: vendorCreditId,
      showRefundMode: true,
    );
  }
}
