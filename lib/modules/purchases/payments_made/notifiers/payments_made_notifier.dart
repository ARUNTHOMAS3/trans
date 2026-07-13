// PATH: lib/modules/purchases/payments_made/notifiers/payments_made_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchases_payments_made_model.dart';
import '../providers/purchases_payments_made_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';

class PaymentsMadeState {
  final List<PaymentMade> payments;
  final bool isLoading;
  final String? errorMessage;
  
  // Create page draft states
  final String paymentNumber;
  final double paymentAmount;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final String? descriptionOfSupply;
  final Vendor? selectedVendor;
  final String location;
  final String paymentMode;
  final String paidThroughAccountId;
  final String depositToAccountId;
  final String sourceOfSupply;
  final String destinationOfSupply;
  final bool reverseCharge;
  final String? selectedTdsTax;
  final String? selectedTax;
  final bool isSaving;

  PaymentsMadeState({
    this.payments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.paymentNumber = '',
    this.paymentAmount = 0.0,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.descriptionOfSupply,
    this.selectedVendor,
    this.location = 'ZABNIX PRIVATE LIMITED',
    this.paymentMode = 'Cash',
    this.paidThroughAccountId = '',
    this.depositToAccountId = 'Prepaid Expenses',
    this.sourceOfSupply = '[KL] - Kerala',
    this.destinationOfSupply = '[KL] - Kerala',
    this.reverseCharge = false,
    this.selectedTdsTax,
    this.selectedTax,
    this.isSaving = false,
  });

  PaymentsMadeState copyWith({
    List<PaymentMade>? payments,
    bool? isLoading,
    String? errorMessage,
    String? paymentNumber,
    double? paymentAmount,
    String? referenceNumber,
    DateTime? paymentDate,
    String? notes,
    String? descriptionOfSupply,
    Vendor? selectedVendor,
    String? location,
    String? paymentMode,
    String? paidThroughAccountId,
    String? depositToAccountId,
    String? sourceOfSupply,
    String? destinationOfSupply,
    bool? reverseCharge,
    String? selectedTdsTax,
    String? selectedTax,
    bool? isSaving,
  }) {
    return PaymentsMadeState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      descriptionOfSupply: descriptionOfSupply ?? this.descriptionOfSupply,
      selectedVendor: selectedVendor ?? this.selectedVendor,
      location: location ?? this.location,
      paymentMode: paymentMode ?? this.paymentMode,
      paidThroughAccountId: paidThroughAccountId ?? this.paidThroughAccountId,
      depositToAccountId: depositToAccountId ?? this.depositToAccountId,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
      destinationOfSupply: destinationOfSupply ?? this.destinationOfSupply,
      reverseCharge: reverseCharge ?? this.reverseCharge,
      selectedTdsTax: selectedTdsTax ?? this.selectedTdsTax,
      selectedTax: selectedTax ?? this.selectedTax,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class PaymentsMadeNotifier extends StateNotifier<PaymentsMadeState> {
  final Ref _ref;

  PaymentsMadeNotifier(this._ref) : super(PaymentsMadeState(paymentDate: DateTime.now())) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = _ref.read(paymentsMadeRepositoryProvider);
      final payments = await repository.getPaymentsMade();
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void updateVendor(Vendor? vendor) {
    state = state.copyWith(selectedVendor: vendor);
  }

  void updatePaymentAmount(double amount) {
    state = state.copyWith(paymentAmount: amount);
  }

  void updatePaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void updatePaidThrough(String accountId) {
    state = state.copyWith(paidThroughAccountId: accountId);
  }

  void updateDepositTo(String accountId) {
    state = state.copyWith(depositToAccountId: accountId);
  }

  void updatePaymentDate(DateTime date) {
    state = state.copyWith(paymentDate: date);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void updateReferenceNumber(String refNum) {
    state = state.copyWith(referenceNumber: refNum);
  }

  void updatePaymentNumber(String num) {
    state = state.copyWith(paymentNumber: num);
  }

  void updateSourceOfSupply(String stateName) {
    state = state.copyWith(sourceOfSupply: stateName);
  }

  void updateDestinationOfSupply(String stateName) {
    state = state.copyWith(destinationOfSupply: stateName);
  }

  void updateReverseCharge(bool reverse) {
    state = state.copyWith(reverseCharge: reverse);
  }

  void updateTdsTax(String? tax) {
    state = state.copyWith(selectedTdsTax: tax);
  }

  void updateTax(String? tax) {
    state = state.copyWith(selectedTax: tax);
  }

  Future<bool> savePayment() async {
    if (state.selectedVendor == null) return false;
    
    state = state.copyWith(isSaving: true);
    try {
      final repository = _ref.read(paymentsMadeRepositoryProvider);
      final newPayment = PaymentMade(
        id: '',
        entityId: '00000000-0000-0000-0000-000000000000', // resolved scope
        vendorId: state.selectedVendor!.id,
        paymentType: 'RECORD_PAYMENT',
        paymentNumber: state.paymentNumber,
        paymentDate: state.paymentDate,
        paymentAmount: state.paymentAmount,
        paidThroughAccountId: state.paidThroughAccountId,
        depositToAccountId: state.depositToAccountId,
        paymentMode: state.paymentMode,
        referenceNumber: state.referenceNumber,
        notes: state.notes,
        status: 'PAID',
      );

      await repository.createPaymentMade(newPayment);
      await loadPayments();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final paymentsMadeNotifierProvider =
    StateNotifierProvider<PaymentsMadeNotifier, PaymentsMadeState>((ref) {
  return PaymentsMadeNotifier(ref);
});
