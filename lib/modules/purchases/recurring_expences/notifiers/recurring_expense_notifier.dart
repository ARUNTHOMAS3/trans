import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_expense_enums.dart';
import '../models/recurring_expense_details_model.dart';
import '../presentation/models/recurring_expense_lookup_models.dart';
import '../config/recurring_expense_constants.dart';

class RecurringExpenseFormState {
  final String profileName;
  final String selectedRepeatEvery;
  final int customRepeatInterval;
  final String selectedCustomRepeatUnit;
  final DateTime startDate;
  final DateTime? endDate;
  final bool neverExpires;
  final String? selectedExpenseAccount;
  final double amount;
  final String selectedCurrency;
  final String? selectedPaidThrough;
  final String expenseType;
  final String? hsnCode;
  final RecurringExpenseVendorOption? selectedVendor;
  final RecurringExpenseCustomerOption? selectedCustomer;
  final String? selectedGstTreatment;
  final String? selectedSourceOfSupply;
  final String? selectedDestinationOfSupply;
  final bool reverseCharge;
  final String? selectedTax;
  final String amountIs;
  final String selectedItcOption;
  final String notes;
  final bool isBillable;
  final bool isSaving;
  final RecurringExpenseDetails? editingProfile;

  RecurringExpenseFormState({
    this.profileName = '',
    this.selectedRepeatEvery =
        RecurringExpenseModuleDefaults.defaultRepeatEvery,
    this.customRepeatInterval = 1,
    this.selectedCustomRepeatUnit =
        RecurringExpenseModuleDefaults.defaultCustomRepeatUnit,
    required this.startDate,
    this.endDate,
    this.neverExpires = false,
    this.selectedExpenseAccount,
    this.amount = 0.0,
    this.selectedCurrency = RecurringExpenseModuleDefaults.defaultCurrency,
    this.selectedPaidThrough,
    this.expenseType = RecurringExpenseModuleDefaults.defaultExpenseType,
    this.hsnCode,
    this.selectedVendor,
    this.selectedCustomer,
    this.selectedGstTreatment,
    this.selectedSourceOfSupply,
    this.selectedDestinationOfSupply,
    this.reverseCharge = false,
    this.selectedTax,
    this.amountIs = RecurringExpenseModuleDefaults.defaultAmountIs,
    this.selectedItcOption = RecurringExpenseModuleDefaults.defaultItcOption,
    this.notes = '',
    this.isBillable = false,
    this.isSaving = false,
    this.editingProfile,
  });

  RecurringExpenseFormState copyWith({
    String? profileName,
    String? selectedRepeatEvery,
    int? customRepeatInterval,
    String? selectedCustomRepeatUnit,
    DateTime? startDate,
    DateTime? endDate,
    bool? neverExpires,
    bool clearEndDate = false,
    String? selectedExpenseAccount,
    double? amount,
    String? selectedCurrency,
    String? selectedPaidThrough,
    String? expenseType,
    String? hsnCode,
    bool clearHsnCode = false,
    RecurringExpenseVendorOption? selectedVendor,
    bool clearVendor = false,
    RecurringExpenseCustomerOption? selectedCustomer,
    bool clearCustomer = false,
    String? selectedGstTreatment,
    bool clearGstTreatment = false,
    String? selectedSourceOfSupply,
    bool clearSourceOfSupply = false,
    String? selectedDestinationOfSupply,
    bool clearDestinationOfSupply = false,
    bool? reverseCharge,
    String? selectedTax,
    bool clearTax = false,
    String? amountIs,
    String? selectedItcOption,
    String? notes,
    bool? isBillable,
    bool? isSaving,
    RecurringExpenseDetails? editingProfile,
    bool clearEditingProfile = false,
  }) {
    return RecurringExpenseFormState(
      profileName: profileName ?? this.profileName,
      selectedRepeatEvery: selectedRepeatEvery ?? this.selectedRepeatEvery,
      customRepeatInterval: customRepeatInterval ?? this.customRepeatInterval,
      selectedCustomRepeatUnit:
          selectedCustomRepeatUnit ?? this.selectedCustomRepeatUnit,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      neverExpires: neverExpires ?? this.neverExpires,
      selectedExpenseAccount:
          selectedExpenseAccount ?? this.selectedExpenseAccount,
      amount: amount ?? this.amount,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      selectedPaidThrough: selectedPaidThrough ?? this.selectedPaidThrough,
      expenseType: expenseType ?? this.expenseType,
      hsnCode: clearHsnCode ? null : (hsnCode ?? this.hsnCode),
      selectedVendor: clearVendor
          ? null
          : (selectedVendor ?? this.selectedVendor),
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      selectedGstTreatment: clearGstTreatment
          ? null
          : (selectedGstTreatment ?? this.selectedGstTreatment),
      selectedSourceOfSupply: clearSourceOfSupply
          ? null
          : (selectedSourceOfSupply ?? this.selectedSourceOfSupply),
      selectedDestinationOfSupply: clearDestinationOfSupply
          ? null
          : (selectedDestinationOfSupply ?? this.selectedDestinationOfSupply),
      reverseCharge: reverseCharge ?? this.reverseCharge,
      selectedTax: clearTax ? null : (selectedTax ?? this.selectedTax),
      amountIs: amountIs ?? this.amountIs,
      selectedItcOption: selectedItcOption ?? this.selectedItcOption,
      notes: notes ?? this.notes,
      isBillable: isBillable ?? this.isBillable,
      isSaving: isSaving ?? this.isSaving,
      editingProfile: clearEditingProfile
          ? null
          : (editingProfile ?? this.editingProfile),
    );
  }
}

class RecurringExpenseNotifier
    extends StateNotifier<RecurringExpenseFormState> {
  RecurringExpenseNotifier()
    : super(
        RecurringExpenseFormState(
          startDate: DateUtils.dateOnly(DateTime.now()),
        ),
      );

  void updateProfileName(String val) =>
      state = state.copyWith(profileName: val);
  void updateRepeatEvery(String val) =>
      state = state.copyWith(selectedRepeatEvery: val);
  void updateCustomRepeatInterval(int val) =>
      state = state.copyWith(customRepeatInterval: val);
  void updateCustomRepeatUnit(String val) =>
      state = state.copyWith(selectedCustomRepeatUnit: val);
  void updateStartDate(DateTime val) => state = state.copyWith(startDate: val);
  void updateEndDate(DateTime? val) =>
      state = state.copyWith(endDate: val, clearEndDate: val == null);
  void updateNeverExpires(bool val) =>
      state = state.copyWith(neverExpires: val);
  void updateExpenseAccount(String? val) =>
      state = state.copyWith(selectedExpenseAccount: val);
  void updateAmount(double val) => state = state.copyWith(amount: val);
  void updateCurrency(String val) =>
      state = state.copyWith(selectedCurrency: val);
  void updatePaidThrough(String? val) =>
      state = state.copyWith(selectedPaidThrough: val);
  void updateExpenseType(String val) =>
      state = state.copyWith(expenseType: val);
  void updateHsnCode(String? val) =>
      state = state.copyWith(hsnCode: val, clearHsnCode: val == null);
  void updateVendor(RecurringExpenseVendorOption? val) =>
      state = state.copyWith(selectedVendor: val, clearVendor: val == null);
  void updateCustomer(RecurringExpenseCustomerOption? val) =>
      state = state.copyWith(selectedCustomer: val, clearCustomer: val == null);
  void updateGstTreatment(String? val) => state = state.copyWith(
    selectedGstTreatment: val,
    clearGstTreatment: val == null,
  );
  void updateSourceOfSupply(String? val) => state = state.copyWith(
    selectedSourceOfSupply: val,
    clearSourceOfSupply: val == null,
  );
  void updateDestinationOfSupply(String? val) => state = state.copyWith(
    selectedDestinationOfSupply: val,
    clearDestinationOfSupply: val == null,
  );
  void updateReverseCharge(bool val) =>
      state = state.copyWith(reverseCharge: val);
  void updateTax(String? val) =>
      state = state.copyWith(selectedTax: val, clearTax: val == null);
  void updateAmountTaxMode(String val) => state = state.copyWith(amountIs: val);
  void updateItcOption(String val) =>
      state = state.copyWith(selectedItcOption: val);
  void updateNotes(String val) => state = state.copyWith(notes: val);
  void updateIsBillable(bool val) => state = state.copyWith(isBillable: val);
  void setSaving(bool val) => state = state.copyWith(isSaving: val);

  void reset() {
    state = RecurringExpenseFormState(
      startDate: DateUtils.dateOnly(DateTime.now()),
    );
  }

  void hydrate(RecurringExpenseDetails profile) {
    state = RecurringExpenseFormState(
      profileName: profile.name,
      selectedRepeatEvery: profile.repeatEvery == 1
          ? profile.repeatType.displayLabel
          : 'Custom',
      customRepeatInterval: profile.repeatEvery,
      selectedCustomRepeatUnit: profile.repeatType.customUnitLabel,
      startDate:
          _parseDate(profile.startDate) ?? DateUtils.dateOnly(DateTime.now()),
      endDate: _parseDate(profile.endDate ?? ''),
      neverExpires: profile.neverExpires,
      selectedExpenseAccount: profile.expenseAccountId,
      amount: profile.amount,
      selectedCurrency: profile.currencyCode,
      selectedPaidThrough: profile.paidThroughId,
      expenseType: profile.expenseType.value == 'Services'
          ? 'Services'
          : 'Goods',
      hsnCode: profile.hsnSacCode,
      selectedVendor: profile.vendorId != null && profile.vendorId!.isNotEmpty
          ? RecurringExpenseVendorOption(
              id: profile.vendorId!,
              displayName: profile.vendorName,
            )
          : null,
      selectedCustomer:
          profile.customerId != null && profile.customerId!.isNotEmpty
          ? RecurringExpenseCustomerOption(
              id: profile.customerId!,
              displayName: profile.customerName,
            )
          : null,
      selectedGstTreatment: profile.gstTreatment,
      selectedSourceOfSupply: profile.sourceOfSupply,
      selectedDestinationOfSupply: profile.destinationOfSupply,
      reverseCharge: profile.reverseCharge,
      selectedTax: profile.taxId,
      amountIs: profile.amountIs,
      notes: profile.notes,
      isBillable: profile.isBillable,
      editingProfile: profile,
    );
  }

  DateTime? _parseDate(String value) {
    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) {
      return DateUtils.dateOnly(parsedIso);
    }
    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
