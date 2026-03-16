// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricelist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceList _$PriceListFromJson(Map<String, dynamic> json) => PriceList(
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
      itemRates: (json['itemRates'] as List<dynamic>?)
          ?.map((e) => PriceListItemRate.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PriceListToJson(PriceList instance) => <String, dynamic>{
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
      'itemRates': instance.itemRates?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

PriceListItemRate _$PriceListItemRateFromJson(Map<String, dynamic> json) =>
    PriceListItemRate(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String?,
      sku: json['sku'] as String?,
      salesRate: (json['salesRate'] as num?)?.toDouble(),
      customRate: (json['customRate'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      volumeRanges: (json['volumeRanges'] as List<dynamic>?)
          ?.map((e) => PriceListVolumeRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PriceListItemRateToJson(PriceListItemRate instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'itemName': instance.itemName,
      'sku': instance.sku,
      'salesRate': instance.salesRate,
      'customRate': instance.customRate,
      'discountPercentage': instance.discountPercentage,
      'volumeRanges': instance.volumeRanges?.map((e) => e.toJson()).toList(),
    };

PriceListVolumeRange _$PriceListVolumeRangeFromJson(
        Map<String, dynamic> json) =>
    PriceListVolumeRange(
      startQuantity: (json['startQuantity'] as num).toDouble(),
      endQuantity: (json['endQuantity'] as num?)?.toDouble(),
      customRate: (json['customRate'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PriceListVolumeRangeToJson(
        PriceListVolumeRange instance) =>
    <String, dynamic>{
      'startQuantity': instance.startQuantity,
      'endQuantity': instance.endQuantity,
      'customRate': instance.customRate,
      'discountPercentage': instance.discountPercentage,
    };
