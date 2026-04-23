// // FILE: lib/modules/items/controller/items_state.dart

// import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
// import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
// import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
// import '../models/composite_item_model.dart';

// class ItemsState {
//   final List<Item> items;
//   final bool isLoading;
//   final bool isSaving;
//   final bool isLoadingLookups;
//   final String? error;

//   // Lookup data
//   final List<Unit> units;
//   final List<Map<String, dynamic>> categories;
//   final List<TaxRate> taxRates;
//   final List<Map<String, dynamic>> manufacturers;
//   final List<Map<String, dynamic>> brands;
//   final List<Map<String, dynamic>> vendors;
//   final List<Map<String, dynamic>> storageLocations;
//   final List<Map<String, dynamic>> racks;
//   final List<Map<String, dynamic>> reorderTerms;
//   final List<Map<String, dynamic>> accounts;

//   // Drug metadata lookups
//   final List<Map<String, dynamic>> contents;
//   final List<Map<String, dynamic>> strengths;
//   final List<Map<String, dynamic>> buyingRules;
//   final List<Map<String, dynamic>> drugSchedules;
//   final List<CompositeItem> compositeItems;

//   final String? selectedItemId;

//   // Validation errors
//   final Map<String, String> validationErrors;

//   const ItemsState({
//     this.items = const [],
//     this.isLoading = false,
//     this.isSaving = false,
//     this.isLoadingLookups = false,
//     this.error,
//     this.selectedItemId,
//     this.units = const [],
//     this.categories = const [],
//     this.taxRates = const [],
//     this.manufacturers = const [],
//     this.brands = const [],
//     this.vendors = const [],
//     this.storageLocations = const [],
//     this.racks = const [],
//     this.reorderTerms = const [],
//     this.accounts = const [],
//     this.contents = const [],
//     this.strengths = const [],
//     this.buyingRules = const [],
//     this.drugSchedules = const [],
//     this.compositeItems = const [],
//     this.validationErrors = const {},
//   });

//   ItemsState copyWith({
//     List<Item>? items,
//     bool? isLoading,
//     bool? isSaving,
//     bool? isLoadingLookups,
//     String? error,
//     String? selectedItemId,
//     List<Unit>? units,
//     List<Map<String, dynamic>>? categories,
//     List<TaxRate>? taxRates,
//     List<Map<String, dynamic>>? manufacturers,
//     List<Map<String, dynamic>>? brands,
//     List<Map<String, dynamic>>? vendors,
//     List<Map<String, dynamic>>? storageLocations,
//     List<Map<String, dynamic>>? racks,
//     List<Map<String, dynamic>>? reorderTerms,
//     List<Map<String, dynamic>>? accounts,
//     List<Map<String, dynamic>>? contents,
//     List<Map<String, dynamic>>? strengths,
//     List<Map<String, dynamic>>? buyingRules,
//     List<Map<String, dynamic>>? drugSchedules,
//     List<CompositeItem>? compositeItems,
//     Map<String, String>? validationErrors,
//   }) {
//     return ItemsState(
//       items: items ?? this.items,
//       isLoading: isLoading ?? this.isLoading,
//       isSaving: isSaving ?? this.isSaving,
//       isLoadingLookups: isLoadingLookups ?? this.isLoadingLookups,
//       error: error,
//       selectedItemId: selectedItemId ?? this.selectedItemId,
//       units: units ?? this.units,
//       categories: categories ?? this.categories,
//       taxRates: taxRates ?? this.taxRates,

//       manufacturers: manufacturers ?? this.manufacturers,
//       brands: brands ?? this.brands,
//       vendors: vendors ?? this.vendors,
//       storageLocations: storageLocations ?? this.storageLocations,
//       racks: racks ?? this.racks,
//       reorderTerms: reorderTerms ?? this.reorderTerms,
//       accounts: accounts ?? this.accounts,
//       contents: contents ?? this.contents,
//       strengths: strengths ?? this.strengths,
//       buyingRules: buyingRules ?? this.buyingRules,
//       drugSchedules: drugSchedules ?? this.drugSchedules,
//       compositeItems: compositeItems ?? this.compositeItems,
//       validationErrors: validationErrors ?? this.validationErrors,
//     );
//   }
// }
// FILE: lib/modules/items/controller/items_state.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/models/uqc_model.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';

final itemsPerPageProvider = StateProvider<int>((ref) => 50);

class ItemsState {
  final List<Item> items;
  final bool isLoading;
  final bool isLoadingList;
  final bool isHydratingItem;
  final String? hydratingItemId;
  final bool isSearching;
  final bool isSaving;
  final bool isLoadingLookups;
  final String? error;
  final int? totalItemsCount;
  final String? nextCursor;
  final bool hasReachedMax;

  // Lookup data
  final List<Unit> units;
  final List<Map<String, dynamic>> categories;
  final List<TaxRate> taxRates;
  final List<TaxRate> taxGroups;
  final List<Map<String, dynamic>> manufacturers;
  final List<Map<String, dynamic>> brands;
  final List<Map<String, dynamic>> vendors;
  final List<Map<String, dynamic>> storageLocations;
  final List<Map<String, dynamic>> racks;
  final List<Map<String, dynamic>> reorderTerms;
  final List<Map<String, dynamic>> accounts;

  // Drug metadata lookups
  final List<Map<String, dynamic>> contents;
  final List<Uqc> uqcList;
  final List<Map<String, dynamic>> strengths;
  final List<Map<String, dynamic>> buyingRules;
  final List<Map<String, dynamic>> drugSchedules;
  final List<CompositeItem> compositeItems;
  final List<Map<String, dynamic>> priceLists;
  final List<Map<String, dynamic>> associatedPriceLists;

  final String? selectedItemId;

  // Validation errors
  final Map<String, String> validationErrors;
  final Map<String, String> lookupCache;

  const ItemsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingList = false,
    this.isHydratingItem = false,
    this.hydratingItemId,
    this.isSearching = false,
    this.isSaving = false,
    this.isLoadingLookups = false,
    this.error,
    this.totalItemsCount,
    this.nextCursor,
    this.hasReachedMax = false,
    this.selectedItemId,
    this.units = const [],
    this.categories = const [],
    this.taxRates = const [],
    this.taxGroups = const [],
    this.manufacturers = const [],
    this.brands = const [],
    this.vendors = const [],
    this.storageLocations = const [],
    this.racks = const [],
    this.reorderTerms = const [],
    this.accounts = const [],
    this.contents = const [],
    this.uqcList = const [],
    this.strengths = const [],
    this.buyingRules = const [],
    this.drugSchedules = const [],
    this.compositeItems = const [],
    this.priceLists = const [],
    this.associatedPriceLists = const [],
    this.validationErrors = const {},
    this.lookupCache = const {},
  });

  ItemsState copyWith({
    List<Item>? items,
    bool? isLoading,
    bool? isLoadingList,
    bool? isHydratingItem,
    Object? hydratingItemId = _sentinel,
    bool? isSearching,
    bool? isSaving,
    bool? isLoadingLookups,
    Object? error = _sentinel,
    int? totalItemsCount,
    Object? nextCursor = _sentinel,
    bool? hasReachedMax,
    String? selectedItemId,
    List<Unit>? units,
    List<Map<String, dynamic>>? categories,
    List<TaxRate>? taxRates,
    List<TaxRate>? taxGroups,
    List<Map<String, dynamic>>? manufacturers,
    List<Map<String, dynamic>>? brands,
    List<Map<String, dynamic>>? vendors,
    List<Map<String, dynamic>>? storageLocations,
    List<Map<String, dynamic>>? racks,
    List<Map<String, dynamic>>? reorderTerms,
    List<Map<String, dynamic>>? accounts,
    List<Map<String, dynamic>>? contents,
    List<Uqc>? uqcList,
    List<Map<String, dynamic>>? strengths,
    List<Map<String, dynamic>>? buyingRules,
    List<Map<String, dynamic>>? drugSchedules,
    List<CompositeItem>? compositeItems,
    List<Map<String, dynamic>>? priceLists,
    List<Map<String, dynamic>>? associatedPriceLists,
    Map<String, String>? validationErrors,
    Map<String, String>? lookupCache,
  }) {
    return ItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isHydratingItem: isHydratingItem ?? this.isHydratingItem,
      hydratingItemId: hydratingItemId == _sentinel
          ? this.hydratingItemId
          : (hydratingItemId as String?),
      isSearching: isSearching ?? this.isSearching,
      isSaving: isSaving ?? this.isSaving,
      isLoadingLookups: isLoadingLookups ?? this.isLoadingLookups,
      error: error == _sentinel ? this.error : (error as String?),
      totalItemsCount: totalItemsCount ?? this.totalItemsCount,
      nextCursor: nextCursor == _sentinel
          ? this.nextCursor
          : (nextCursor as String?),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedItemId: selectedItemId ?? this.selectedItemId,
      units: units ?? this.units,
      categories: categories ?? this.categories,
      taxRates: taxRates ?? this.taxRates,
      taxGroups: taxGroups ?? this.taxGroups,
      manufacturers: manufacturers ?? this.manufacturers,
      brands: brands ?? this.brands,
      vendors: vendors ?? this.vendors,
      storageLocations: storageLocations ?? this.storageLocations,
      racks: racks ?? this.racks,
      reorderTerms: reorderTerms ?? this.reorderTerms,
      accounts: accounts ?? this.accounts,
      contents: contents ?? this.contents,
      uqcList: uqcList ?? this.uqcList,
      strengths: strengths ?? this.strengths,
      buyingRules: buyingRules ?? this.buyingRules,
      drugSchedules: drugSchedules ?? this.drugSchedules,
      compositeItems: compositeItems ?? this.compositeItems,
      priceLists: priceLists ?? this.priceLists,
      associatedPriceLists: associatedPriceLists ?? this.associatedPriceLists,
      validationErrors: validationErrors ?? this.validationErrors,
      lookupCache: lookupCache ?? this.lookupCache,
    );
  }

  static const _sentinel = Object();
}
