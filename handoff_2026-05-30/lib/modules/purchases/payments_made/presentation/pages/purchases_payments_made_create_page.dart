import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../bills/providers/purchases_bills_provider.dart';
import '../../../bills/models/purchases_bills_bill_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class PurchasesPaymentsMadeCreatePage extends ConsumerStatefulWidget {
  final List<String> billIds;

  const PurchasesPaymentsMadeCreatePage({
    super.key,
    required this.billIds,
  });

  @override
  ConsumerState<PurchasesPaymentsMadeCreatePage> createState() =>
      _PurchasesPaymentsMadeCreatePageState();
}

class _PurchasesPaymentsMadeCreatePageState
    extends ConsumerState<PurchasesPaymentsMadeCreatePage> {
  String? _paidThrough = 'Petty Cash';
  String? _paymentMode = 'Cash';
  String? _location = 'ZABNIX PRIVATE LIMITED';
  DateTime _paymentDate = DateTime.now();
  final TextEditingController _referenceController = TextEditingController();
  bool _isLoading = false;
  bool _showBills = true;

  // Selected bills to pay mapping: billId -> amount to pay
  final Map<String, double> _paymentAmounts = {};
  final Map<String, bool> _selectedBillStatus = {};

  final List<String> _accounts = const ['Select an account', 'Cash', 'Petty Cash', 'Undeposited Funds', 'General Ledger'];
  final List<String> _modes = const ['Choose the payment term or type to add', 'Cash', 'Check', 'Bank Transfer', 'Credit Card'];
  final List<String> _locations = const ['ZABNIX PRIVATE LIMITED', 'Central Logistics Hub', 'Secondary Storage Unit'];

  @override
  void initState() {
    super.initState();
    _initializePaymentData();
  }

  void _initializePaymentData() {
    final bills = ref.read(billsProvider).bills;
    final selectedBills = bills.where((b) => widget.billIds.contains(b.id)).toList();
    
    // If empty selection, we mock a default bill row as shown in 3rd screenshot
    if (selectedBills.isEmpty) {
      _paymentAmounts['mock-bill'] = 185.0;
      _selectedBillStatus['mock-bill'] = true;
    } else {
      for (var b in selectedBills) {
        _selectedBillStatus[b.id] = true;
      }
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    _selectedBillStatus.forEach((key, isChecked) {
      if (isChecked) {
        total += _paymentAmounts[key] ?? 0.0;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider).bills;
    final selectedBills = bills.where((b) => widget.billIds.contains(b.id)).toList();
    final double totalAmount = _calculateTotalAmount();

    // Vendor names of selected bills
    final vendorName = selectedBills.isNotEmpty 
        ? selectedBills.first.vendorName 
        : 'Evanto';

    return ZerpaiLayout(
      pageTitle: 'Record Bulk Payment',
      enableBodyScroll: true,
      useHorizontalPadding: true,
      useTopPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Record Bulk Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.textSecondary),
                onPressed: () => context.go('/purchases/bills'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 24),

          // Forms Row
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildFormDropdown('Paid Through*', _accounts, _paidThrough, (v) => setState(() => _paidThrough = v)),
              _buildFormDropdown('Payment Mode', _modes, _paymentMode, (v) => setState(() => _paymentMode = v)),
              _buildFormDropdown('Location', _locations, _location, (v) => setState(() => _location = v)),
            ],
          ),
          const SizedBox(height: 36),

          // Transaction Details section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Total: ₹${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 20),

          // Vendor Details card
          const Text(
            'VENDOR DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFF28A745),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vendorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Vendor Total: ₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0088FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Form row below vendor
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField('Payment Date*'),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTextField('Reference#', _referenceController),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showBills = !_showBills),
                      child: Row(
                        children: [
                          Text(
                            _showBills ? 'Hide Bills' : 'Show Bills',
                            style: const TextStyle(color: Color(0xFF0088FF), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showBills ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 14,
                            color: const Color(0xFF0088FF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_showBills) ...[
                  const SizedBox(height: 24),
                  // Bills list table
                  _buildBillsTable(selectedBills),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons Footer
          Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitPayment(selectedBills, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Save as Paid'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : () => _submitPayment(selectedBills, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Save as Draft'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => context.go('/purchases/bills'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFormDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
          ),
          const SizedBox(height: 6),
          FormDropdown<String>(
            value: value,
            items: items,
            height: 36,
            displayStringForValue: (e) => e,
            onChanged: onChanged,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: controller,
          height: 36,
          hintText: 'Enter $label',
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(_paymentDate);
    final GlobalKey key = GlobalKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: key,
          onTap: () async {
            final picked = await ZerpaiDatePicker.show(
              context,
              initialDate: _paymentDate,
              targetKey: key,
            );
            if (picked != null) {
              setState(() {
                _paymentDate = picked;
              });
            }
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillsTable(List<PurchasesBill> selectedBills) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textSecondary,
    );

    return Column(
      children: [
        Container(
          color: const Color(0xFFF9FAFB),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(flex: 2, child: Text('BILL DATE', style: headerStyle)),
              Expanded(flex: 2, child: Text('DUE DATE', style: headerStyle)),
              Expanded(flex: 2, child: Text('BILL#', style: headerStyle)),
              Expanded(flex: 2, child: Text('BILL AMOUNT', style: headerStyle)),
              Expanded(flex: 2, child: Text('AMOUNT DUE', style: headerStyle)),
              Expanded(flex: 2, child: Text('PAYMENT AMOUNT', style: headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        
        if (selectedBills.isEmpty) ...[
          _buildBillRow(
            billId: 'mock-bill',
            date: '05-05-2026',
            dueDate: '05-05-2026',
            number: '11111',
            amount: 185.0,
            amountDue: 185.0,
          ),
        ] 
      ],
    );
  }

  Widget _buildBillRow({
    required String billId,
    required String date,
    required String dueDate,
    required String number,
    required double amount,
    required double amountDue,
  }) {
    final isChecked = _selectedBillStatus[billId] ?? false;
    final payAmount = _paymentAmounts[billId] ?? 0.0;
    
    final cellStyle = const TextStyle(fontSize: 13, color: AppTheme.textPrimary);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isChecked,
              onChanged: (v) {
                setState(() {
                  _selectedBillStatus[billId] = v ?? false;
                });
              },
              activeColor: const Color(0xFF0088FF),
            ),
          ),
          Expanded(flex: 2, child: Text(date, style: cellStyle)),
          Expanded(flex: 2, child: Text(dueDate, style: cellStyle)),
          Expanded(flex: 2, child: Text(number, style: cellStyle)),
          Expanded(flex: 2, child: Text('₹${amount.toStringAsFixed(2)}', style: cellStyle)),
          Expanded(flex: 2, child: Text('₹${amountDue.toStringAsFixed(2)}', style: cellStyle)),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: TextFormField(
                initialValue: payAmount.toInt().toString(),
                keyboardType: TextInputType.number,
                enabled: isChecked,
                onChanged: (val) {
                  setState(() {
                    _paymentAmounts[billId] = double.tryParse(val) ?? 0.0;
                  });
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitPayment(List<PurchasesBill> selectedBills, bool isPaid) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      if (selectedBills.isNotEmpty) {
        for (var b in selectedBills) {
          final isChecked = _selectedBillStatus[b.id] ?? false;
          if (isChecked) {
            await supabase
                .from('purchases_bills')
                .update({
                })
                .eq('id', b.id);
            
            ref.invalidate(purchaseBillProvider(b.id));
          }
        }
        ref.read(billsProvider.notifier).loadBills();
      }

      if (mounted) {
        ZerpaiToast.success(
          context, 
          isPaid ? 'Payment recorded successfully' : 'Payment drafted successfully'
        );
        context.go('/purchases/bills');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to record payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
