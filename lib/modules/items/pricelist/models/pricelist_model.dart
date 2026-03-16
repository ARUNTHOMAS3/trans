import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pricelist_model.g.dart';

/// Represents a price list in the Zerpai ERP system
@JsonSerializable(explicitToJson: true)
class PriceList extends Equatable {
  /// Unique identifier for the price list
  final String id;

  /// Name of the price list
  final String name;

  /// Optional description of the price list
  final String? description;

  // TODO: Add support for multi-currency conversion in calculations
  // TODO: Implement item-group based pricing rules
  // TODO: Add tax-inclusive/exclusive calculation flags

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

  /// Custom rates for individual items (only used if priceListType is 'individual_items')
  final List<PriceListItemRate>? itemRates;

  /// Timestamp when the price list was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Timestamp when the price list was last updated
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const PriceList({
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
    this.itemRates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PriceList.fromJson(Map<String, dynamic> json) =>
      _$PriceListFromJson(json);

  Map<String, dynamic> toJson() => _$PriceListToJson(this);

  PriceList copyWith({
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
    List<PriceListItemRate>? itemRates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PriceList(
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
      itemRates: itemRates ?? this.itemRates,
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
        orElse: () => const PriceListItemRate(itemId: ''),
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
    itemRates,
    createdAt,
    updatedAt,
  ];
}

/// Custom rate for an individual item in a price list
@JsonSerializable(explicitToJson: true)
class PriceListItemRate extends Equatable {
  final String itemId;
  final String? itemName;
  final String? sku;
  final double? salesRate; // Base rate from the item
  final double? customRate; // Flat rate (used in Unit Pricing)
  final double? discountPercentage;
  final List<PriceListVolumeRange>?
  volumeRanges; // Multi-tier rates (used in Volume Pricing)

  const PriceListItemRate({
    required this.itemId,
    this.itemName,
    this.sku,
    this.salesRate,
    this.customRate,
    this.discountPercentage,
    this.volumeRanges,
  });

  factory PriceListItemRate.fromJson(Map<String, dynamic> json) =>
      _$PriceListItemRateFromJson(json);

  Map<String, dynamic> toJson() => _$PriceListItemRateToJson(this);

  PriceListItemRate copyWith({
    String? itemId,
    String? itemName,
    String? sku,
    double? salesRate,
    double? customRate,
    double? discountPercentage,
    List<PriceListVolumeRange>? volumeRanges,
  }) {
    return PriceListItemRate(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      sku: sku ?? this.sku,
      salesRate: salesRate ?? this.salesRate,
      customRate: customRate ?? this.customRate,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      volumeRanges: volumeRanges ?? this.volumeRanges,
    );
  }

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

/// Volume-based pricing range for an item
@JsonSerializable()
class PriceListVolumeRange extends Equatable {
  final double startQuantity;
  final double? endQuantity;
  final double customRate;
  final double? discountPercentage;

  const PriceListVolumeRange({
    required this.startQuantity,
    this.endQuantity,
    required this.customRate,
    this.discountPercentage,
  });

  factory PriceListVolumeRange.fromJson(Map<String, dynamic> json) =>
      _$PriceListVolumeRangeFromJson(json);

  Map<String, dynamic> toJson() => _$PriceListVolumeRangeToJson(this);

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
