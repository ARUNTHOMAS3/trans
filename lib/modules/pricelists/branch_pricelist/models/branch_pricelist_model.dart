import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'branch_pricelist_model.g.dart';

/// Represents a branch-specific price list in the Zerpai ERP system
@JsonSerializable(explicitToJson: true)
class BranchPriceList extends Equatable {
  /// Unique identifier for the price list
  final String id;

  /// Name of the price list
  final String name;

  /// Optional description of the price list
  final String? description;

  /// Currency code (e.g., 'INR', 'USD')
  final String? currency;

  /// Type of pricing scheme ('unit_pricing', 'volume_pricing', 'markup', 'markdown')
  @JsonKey(name: 'pricing_scheme')
  final String pricingScheme;

  /// Price list type ('all_items', 'individual_items')
  @JsonKey(name: 'price_list_type')
  final String priceListType;

  /// Details about the pricing (e.g., percentage for markup/markdown)
  final String? details;

  /// Round off preference
  @JsonKey(name: 'round_off_preference')
  final String? roundOffPreference;

  /// Status of the price list ('active', 'inactive')
  final String status;

  /// Transaction type ('Sales', 'Purchase')
  @JsonKey(name: 'transaction_type')
  final String transactionType;

  /// Whether discount percentage is included
  @JsonKey(name: 'discount_enabled', defaultValue: false)
  final bool isDiscountEnabled;

  /// Whether seasonal price list is enabled
  @JsonKey(name: 'seasonal_enabled', defaultValue: false)
  final bool isSeasonalEnabled;

  /// Start date for seasonal price list
  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  /// End date for seasonal price list
  @JsonKey(name: 'end_date')
  final DateTime? endDate;

  /// Custom rates for individual items (only used if priceListType is 'individual_items')
  @JsonKey(name: 'item_rates')
  final List<BranchPriceListItemRate>? itemRates;

  /// Associated branch names selected when creating the price list
  @JsonKey(name: 'associated_branches')
  final List<String>? associatedBranches;

  /// Timestamp when the price list was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Timestamp when the price list was last updated
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const BranchPriceList({
    required this.id,
    required this.name,
    this.description,
    this.currency,
    required this.pricingScheme,
    this.priceListType = 'all_items',
    this.details,
    this.roundOffPreference,
    required this.status,
    this.transactionType = 'Sales',
    this.isDiscountEnabled = false,
    this.isSeasonalEnabled = false,
    this.startDate,
    this.endDate,
    this.itemRates,
    this.associatedBranches,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchPriceList.fromJson(Map<String, dynamic> json) =>
      _$BranchPriceListFromJson(json);

  Map<String, dynamic> toJson() => _$BranchPriceListToJson(this);

  BranchPriceList copyWith({
    String? id,
    String? name,
    String? description,
    String? currency,
    String? pricingScheme,
    String? priceListType,
    String? details,
    String? roundOffPreference,
    String? status,
    String? transactionType,
    bool? isDiscountEnabled,
    bool? isSeasonalEnabled,
    DateTime? startDate,
    DateTime? endDate,
    List<BranchPriceListItemRate>? itemRates,
    List<String>? associatedBranches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchPriceList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      pricingScheme: pricingScheme ?? this.pricingScheme,
      priceListType: priceListType ?? this.priceListType,
      details: details ?? this.details,
      roundOffPreference: roundOffPreference ?? this.roundOffPreference,
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      isDiscountEnabled: isDiscountEnabled ?? this.isDiscountEnabled,
      isSeasonalEnabled: isSeasonalEnabled ?? this.isSeasonalEnabled,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      itemRates: itemRates ?? this.itemRates,
      associatedBranches: associatedBranches ?? this.associatedBranches,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates the price for an item based on this price list
  double calculatePrice(String itemId, double baseRate, {double quantity = 1}) {
    double rate = baseRate;

    if (priceListType == 'all_items') {
      final percentage =
          double.tryParse(
            RegExp(r'(\d+\.?\d*)').firstMatch(details ?? '')?.group(0) ?? '0',
          ) ??
          0.0;
      if (details?.toLowerCase().contains('markup') ?? false) {
        rate = baseRate * (1 + percentage / 100);
      } else if (details?.toLowerCase().contains('markdown') ?? false) {
        rate = baseRate * (1 - percentage / 100);
      }
    } else {
      final override = itemRates?.firstWhere(
        (r) => r.itemId == itemId,
        orElse: () => const BranchPriceListItemRate(itemId: ''),
      );
      if (override != null && override.itemId.isNotEmpty) {
        if (pricingScheme == 'volume_pricing' &&
            override.volumeRanges != null) {
          for (var range in override.volumeRanges!) {
            if (quantity >= range.startQuantity &&
                (range.endQuantity == null || quantity <= range.endQuantity!)) {
              rate = range.customRate;
              break;
            }
          }
        } else if (override.customRate != null) {
          rate = override.customRate!;
        }
      }
    }

    // Apply rounding
    switch (roundOffPreference) {
      case 'To the nearest .99':
        rate = rate.floorToDouble() + 0.99;
        break;
      case 'To the nearest .50':
        rate = (rate * 2).roundToDouble() / 2;
        break;
      case 'To the nearest whole number':
        rate = rate.roundToDouble();
        break;
    }

    return rate;
  }

  /// Creates a dummy BranchPriceList for loading states
  factory BranchPriceList.dummy() => BranchPriceList(
    id: 'dummy-id',
    name: 'Loading Branch Price List...',
    description: 'Loading description...',
    pricingScheme: 'unit_pricing',
    priceListType: 'all_items',
    status: 'active',
    transactionType: 'Sales',
    isSeasonalEnabled: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Creates a list of dummy BranchPriceLists
  static List<BranchPriceList> dummyList([int count = 5]) =>
      List.generate(count, (_) => BranchPriceList.dummy());

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    currency,
    pricingScheme,
    priceListType,
    details,
    roundOffPreference,
    status,
    transactionType,
    isDiscountEnabled,
    isSeasonalEnabled,
    startDate,
    endDate,
    itemRates,
    associatedBranches,
    createdAt,
    updatedAt,
  ];
}

/// Custom rate for an individual item in a branch price list
@JsonSerializable(explicitToJson: true)
class BranchPriceListItemRate extends Equatable {
  @JsonKey(name: 'item_id')
  final String itemId;
  @JsonKey(name: 'item_name')
  final String? itemName;
  final String? sku;
  @JsonKey(name: 'sales_rate')
  final double? salesRate;
  @JsonKey(name: 'custom_rate')
  final double? customRate;
  @JsonKey(name: 'discount_percentage')
  final double? discountPercentage;
  @JsonKey(name: 'volume_ranges')
  final List<BranchPriceListVolumeRange>? volumeRanges;

  const BranchPriceListItemRate({
    required this.itemId,
    this.itemName,
    this.sku,
    this.salesRate,
    this.customRate,
    this.discountPercentage,
    this.volumeRanges,
  });

  factory BranchPriceListItemRate.fromJson(Map<String, dynamic> json) =>
      _$BranchPriceListItemRateFromJson(json);

  Map<String, dynamic> toJson() => _$BranchPriceListItemRateToJson(this);

  BranchPriceListItemRate copyWith({
    String? itemId,
    String? itemName,
    String? sku,
    double? salesRate,
    double? customRate,
    double? discountPercentage,
    List<BranchPriceListVolumeRange>? volumeRanges,
  }) {
    return BranchPriceListItemRate(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      sku: sku ?? this.sku,
      salesRate: salesRate ?? this.salesRate,
      customRate: customRate ?? this.customRate,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      volumeRanges: volumeRanges ?? this.volumeRanges,
    );
  }

  /// Creates a dummy BranchPriceListItemRate for loading states
  factory BranchPriceListItemRate.dummy() => const BranchPriceListItemRate(
    itemId: 'dummy-item-id',
    itemName: 'Loading Item Name...',
    sku: 'SKU-DUMMY',
    salesRate: 100.0,
    customRate: 90.0,
    discountPercentage: 10.0,
  );

  /// Creates a list of dummy BranchPriceListItemRates
  static List<BranchPriceListItemRate> dummyList([int count = 5]) =>
      List.generate(count, (_) => BranchPriceListItemRate.dummy());

  @override
  List<Object?> get props => [
    itemId,
    itemName,
    sku,
    salesRate,
    customRate,
    discountPercentage,
    volumeRanges,
  ];
}

/// Volume-based pricing range for an item in a branch price list
@JsonSerializable()
class BranchPriceListVolumeRange extends Equatable {
  @JsonKey(name: 'start_quantity')
  final double startQuantity;
  @JsonKey(name: 'end_quantity')
  final double? endQuantity;
  @JsonKey(name: 'custom_rate')
  final double customRate;
  @JsonKey(name: 'discount_percentage')
  final double? discountPercentage;

  const BranchPriceListVolumeRange({
    required this.startQuantity,
    this.endQuantity,
    required this.customRate,
    this.discountPercentage,
  });

  factory BranchPriceListVolumeRange.fromJson(Map<String, dynamic> json) =>
      _$BranchPriceListVolumeRangeFromJson(json);

  Map<String, dynamic> toJson() => _$BranchPriceListVolumeRangeToJson(this);

  @override
  List<Object?> get props => [
    startQuantity,
    endQuantity,
    customRate,
    discountPercentage,
  ];
}





/// Enum for different pricing schemes
enum PricingScheme {
  unitPricing('unit_pricing'),
  volumePricing('volume_pricing'),
  markup('markup'),
  markdown('markdown'),
  perItemRate('per_item_rate');

  const PricingScheme(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case PricingScheme.unitPricing:
        return 'Unit Pricing';
      case PricingScheme.volumePricing:
        return 'Volume Pricing';
      case PricingScheme.markup:
        return 'Markup';
      case PricingScheme.markdown:
        return 'Markdown';
      case PricingScheme.perItemRate:
        return 'Per Item Rate';
    }
  }
}

/// Enum for round off preferences
enum RoundOffPreference {
  neverMind('never_mind'),
  pointNineNine('.99'),
  pointFive('.50'),
  wholeNumber('0'),
  pointTwoFive('.25');

  const RoundOffPreference(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case RoundOffPreference.neverMind:
        return 'Never mind';
      case RoundOffPreference.pointNineNine:
        return '0.99';
      case RoundOffPreference.pointFive:
        return '0.50';
      case RoundOffPreference.wholeNumber:
        return '0';
      case RoundOffPreference.pointTwoFive:
        return '0.25';
    }
  }
}

