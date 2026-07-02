// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_pricelist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchPriceList _$BranchPriceListFromJson(Map<String, dynamic> json) =>
    BranchPriceList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String?,
      pricingScheme: json['pricing_scheme'] as String,
      priceListType: json['price_list_type'] as String? ?? 'all_items',
      details: json['details'] as String?,
      roundOffPreference: json['round_off_preference'] as String?,
      status: json['status'] as String,
      transactionType: json['transaction_type'] as String? ?? 'Sales',
      isDiscountEnabled: json['discount_enabled'] as bool? ?? false,
      isSeasonalEnabled: json['seasonal_enabled'] as bool? ?? false,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      itemRates: (json['item_rates'] as List<dynamic>?)
          ?.map((e) =>
              BranchPriceListItemRate.fromJson(e as Map<String, dynamic>))
          .toList(),
      associatedBranches: (json['associated_branches'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      percentageType: json['percentage_type'] as String?,
      percentageValue: (json['percentage_value'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BranchPriceListToJson(BranchPriceList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'currency': instance.currency,
      'pricing_scheme': instance.pricingScheme,
      'price_list_type': instance.priceListType,
      'details': instance.details,
      'round_off_preference': instance.roundOffPreference,
      'status': instance.status,
      'transaction_type': instance.transactionType,
      'discount_enabled': instance.isDiscountEnabled,
      'seasonal_enabled': instance.isSeasonalEnabled,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'item_rates': instance.itemRates?.map((e) => e.toJson()).toList(),
      'associated_branches': instance.associatedBranches,
      'percentage_type': instance.percentageType,
      'percentage_value': instance.percentageValue,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

BranchPriceListItemRate _$BranchPriceListItemRateFromJson(
        Map<String, dynamic> json) =>
    BranchPriceListItemRate(
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String?,
      sku: json['sku'] as String?,
      salesRate: (json['sales_rate'] as num?)?.toDouble(),
      customRate: (json['custom_rate'] as num?)?.toDouble(),
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      volumeRanges: (json['volume_ranges'] as List<dynamic>?)
          ?.map((e) =>
              BranchPriceListVolumeRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BranchPriceListItemRateToJson(
        BranchPriceListItemRate instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'item_name': instance.itemName,
      'sku': instance.sku,
      'sales_rate': instance.salesRate,
      'custom_rate': instance.customRate,
      'discount_percentage': instance.discountPercentage,
      'volume_ranges': instance.volumeRanges?.map((e) => e.toJson()).toList(),
    };

BranchPriceListVolumeRange _$BranchPriceListVolumeRangeFromJson(
        Map<String, dynamic> json) =>
    BranchPriceListVolumeRange(
      startQuantity: (json['start_quantity'] as num).toDouble(),
      endQuantity: (json['end_quantity'] as num?)?.toDouble(),
      customRate: (json['custom_rate'] as num).toDouble(),
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BranchPriceListVolumeRangeToJson(
        BranchPriceListVolumeRange instance) =>
    <String, dynamic>{
      'start_quantity': instance.startQuantity,
      'end_quantity': instance.endQuantity,
      'custom_rate': instance.customRate,
      'discount_percentage': instance.discountPercentage,
    };
