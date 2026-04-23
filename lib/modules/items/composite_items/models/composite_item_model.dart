import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

// import 'item_model.dart';

class CompositePart {
  final String? id;
  final String componentProductId;
  final double quantity;
  final double? sellingPriceOverride;
  final double? costPriceOverride;
  final Item? product; // Optional: loaded standard item

  CompositePart({
    this.id,
    required this.componentProductId,
    required this.quantity,
    this.sellingPriceOverride,
    this.costPriceOverride,
    this.product,
  });

  factory CompositePart.fromJson(Map<String, dynamic> json) {
    return CompositePart(
      id: json['id']?.toString(),
      componentProductId: json['component_product_id'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      sellingPriceOverride: json['selling_price_override'] != null
          ? double.tryParse(json['selling_price_override'].toString())
          : null,
      costPriceOverride: json['cost_price_override'] != null
          ? double.tryParse(json['cost_price_override'].toString())
          : null,
      product: json['product'] != null ? Item.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'component_product_id': componentProductId,
      'quantity': quantity,
      if (sellingPriceOverride != null)
        'selling_price_override': sellingPriceOverride,
      if (costPriceOverride != null) 'cost_price_override': costPriceOverride,
    };
  }
}

class CompositeItem {
  final String? id;
  final String type; // 'goods' or 'service'
  final String productName;
  final String? sku;
  final String unitId;
  final String? categoryId;
  final bool isReturnable;
  final bool pushToEcommerce;
  final String? hsnCode;
  final String? taxPreference;
  final String? intraStateTaxId;
  final String? interStateTaxId;
  final String? primaryImageUrl;
  final List<String>? imageUrls;
  final double? sellingPrice;
  final String? salesAccountId;
  final String? salesDescription;
  final double? costPrice;
  final String? purchaseAccountId;
  final String? preferredVendorId;
  final String? purchaseDescription;
  final double? length;
  final double? width;
  final double? height;
  final String dimensionUnit;
  final double? weight;
  final String weightUnit;
  final String? manufacturerId;
  final String? brandId;
  final String? mpn;
  final String? upc;
  final String? isbn;
  final String? ean;
  final bool isTrackInventory;
  final bool trackBatches;
  final bool trackSerialNumber;
  final bool trackBinLocation;
  final String? inventoryAccountId;
  final String? inventoryValuationMethod;
  final int reorderPoint;
  final String? reorderTermId;
  final bool isActive;
  final bool isLock;
  final List<CompositePart>? parts;
  final DateTime? createdAt;
  final String? createdById;
  final DateTime? updatedAt;
  final String? updatedById;

  CompositeItem({
    this.id,
    required this.type,
    required this.productName,
    this.sku,
    required this.unitId,
    this.categoryId,
    this.isReturnable = false,
    this.pushToEcommerce = false,
    this.hsnCode,
    this.taxPreference,
    this.intraStateTaxId,
    this.interStateTaxId,
    this.primaryImageUrl,
    this.imageUrls,
    this.sellingPrice,
    this.salesAccountId,
    this.salesDescription,
    this.costPrice,
    this.purchaseAccountId,
    this.preferredVendorId,
    this.purchaseDescription,
    this.length,
    this.width,
    this.height,
    this.dimensionUnit = 'cm',
    this.weight,
    this.weightUnit = 'kg',
    this.manufacturerId,
    this.brandId,
    this.mpn,
    this.upc,
    this.isbn,
    this.ean,
    this.isTrackInventory = true,
    this.trackBatches = false,
    this.trackSerialNumber = false,
    this.trackBinLocation = false,
    this.inventoryAccountId,
    this.inventoryValuationMethod,
    this.reorderPoint = 0,
    this.reorderTermId,
    this.isActive = true,
    this.isLock = false,
    this.parts,
    this.createdAt,
    this.createdById,
    this.updatedAt,
    this.updatedById,
  });

  factory CompositeItem.fromJson(Map<String, dynamic> json) {
    return CompositeItem(
      id: json['id']?.toString(),
      type: json['type'] ?? 'goods',
      productName: json['product_name'] ?? '',
      sku: json['sku'],
      unitId: json['unit_id'] ?? '',
      categoryId: json['category_id'],
      isReturnable: json['is_returnable'] ?? false,
      pushToEcommerce: json['push_to_ecommerce'] ?? false,
      hsnCode: json['hsn_code'],
      taxPreference: json['tax_preference'],
      intraStateTaxId: json['intra_state_tax_id'],
      interStateTaxId: json['inter_state_tax_id'],
      primaryImageUrl: json['primary_image_url'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      sellingPrice: json['selling_price'] != null
          ? double.tryParse(json['selling_price'].toString())
          : null,
      salesAccountId: json['sales_account_id'],
      salesDescription: json['sales_description'],
      costPrice: json['cost_price'] != null
          ? double.tryParse(json['cost_price'].toString())
          : null,
      purchaseAccountId: json['purchase_account_id'],
      preferredVendorId: json['preferred_vendor_id'],
      purchaseDescription: json['purchase_description'],
      length: json['length'] != null
          ? double.tryParse(json['length'].toString())
          : null,
      width: json['width'] != null
          ? double.tryParse(json['width'].toString())
          : null,
      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,
      dimensionUnit: json['dimension_unit'] ?? 'cm',
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      weightUnit: json['weight_unit'] ?? 'kg',
      manufacturerId: json['manufacturer_id'],
      brandId: json['brand_id'],
      mpn: json['mpn'],
      upc: json['upc'],
      isbn: json['isbn'],
      ean: json['ean'],
      isTrackInventory: json['is_track_inventory'] ?? true,
      trackBatches: json['track_batches'] ?? false,
      trackSerialNumber: json['track_serial_number'] ?? false,
      trackBinLocation: json['track_bin_location'] ?? false,
      inventoryAccountId: json['inventory_account_id'],
      inventoryValuationMethod: json['inventory_valuation_method'],
      reorderPoint: json['reorder_point'] ?? 0,
      reorderTermId: json['reorder_term_id'],
      isActive: json['is_active'] ?? true,
      isLock: json['is_lock'] ?? false,
      parts: json['parts'] != null
          ? (json['parts'] as List)
                .map((p) => CompositePart.fromJson(p))
                .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'product_name': productName,
      if (sku != null) 'sku': sku,
      'unit_id': unitId,
      if (categoryId != null) 'category_id': categoryId,
      'is_returnable': isReturnable,
      'push_to_ecommerce': pushToEcommerce,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (taxPreference != null) 'tax_preference': taxPreference,
      if (intraStateTaxId != null) 'intra_state_tax_id': intraStateTaxId,
      if (interStateTaxId != null) 'inter_state_tax_id': interStateTaxId,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (salesAccountId != null) 'sales_account_id': salesAccountId,
      if (salesDescription != null) 'sales_description': salesDescription,
      if (costPrice != null) 'cost_price': costPrice,
      if (purchaseAccountId != null) 'purchase_account_id': purchaseAccountId,
      if (preferredVendorId != null) 'preferred_vendor_id': preferredVendorId,
      if (purchaseDescription != null)
        'purchase_description': purchaseDescription,
      if (length != null) 'length': length,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'dimension_unit': dimensionUnit,
      if (weight != null) 'weight': weight,
      'weight_unit': weightUnit,
      if (manufacturerId != null) 'manufacturer_id': manufacturerId,
      if (brandId != null) 'brand_id': brandId,
      if (mpn != null) 'mpn': mpn,
      if (upc != null) 'upc': upc,
      if (isbn != null) 'isbn': isbn,
      if (ean != null) 'ean': ean,
      'is_track_inventory': isTrackInventory,
      'track_batches': trackBatches,
      'track_serial_number': trackSerialNumber,
      'track_bin_location': trackBinLocation,
      if (inventoryAccountId != null)
        'inventory_account_id': inventoryAccountId,
      if (inventoryValuationMethod != null)
        'inventory_valuation_method': inventoryValuationMethod,
      'reorder_point': reorderPoint,
      if (reorderTermId != null) 'reorder_term_id': reorderTermId,
      'is_active': isActive,
      'is_lock': isLock,
      if (parts != null) 'parts': parts!.map((p) => p.toJson()).toList(),
    };
  }

  CompositeItem copyWith({
    String? id,
    String? type,
    String? productName,
    String? sku,
    String? unitId,
    String? categoryId,
    bool? isReturnable,
    bool? pushToEcommerce,
    String? hsnCode,
    String? taxPreference,
    String? intraStateTaxId,
    String? interStateTaxId,
    String? primaryImageUrl,
    List<String>? imageUrls,
    double? sellingPrice,
    String? salesAccountId,
    String? salesDescription,
    double? costPrice,
    String? purchaseAccountId,
    String? preferredVendorId,
    String? purchaseDescription,
    double? length,
    double? width,
    double? height,
    String? dimensionUnit,
    double? weight,
    String? weightUnit,
    String? manufacturerId,
    String? brandId,
    String? mpn,
    String? upc,
    String? isbn,
    String? ean,
    bool? isTrackInventory,
    bool? trackBatches,
    bool? trackSerialNumber,
    bool? trackBinLocation,
    String? inventoryAccountId,
    String? inventoryValuationMethod,
    int? reorderPoint,
    String? reorderTermId,
    bool? isActive,
    bool? isLock,
    List<CompositePart>? parts,
    DateTime? createdAt,
    String? createdById,
    DateTime? updatedAt,
    String? updatedById,
  }) {
    return CompositeItem(
      id: id ?? this.id,
      type: type ?? this.type,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitId: unitId ?? this.unitId,
      categoryId: categoryId ?? this.categoryId,
      isReturnable: isReturnable ?? this.isReturnable,
      pushToEcommerce: pushToEcommerce ?? this.pushToEcommerce,
      hsnCode: hsnCode ?? this.hsnCode,
      taxPreference: taxPreference ?? this.taxPreference,
      intraStateTaxId: intraStateTaxId ?? this.intraStateTaxId,
      interStateTaxId: interStateTaxId ?? this.interStateTaxId,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      salesAccountId: salesAccountId ?? this.salesAccountId,
      salesDescription: salesDescription ?? this.salesDescription,
      costPrice: costPrice ?? this.costPrice,
      purchaseAccountId: purchaseAccountId ?? this.purchaseAccountId,
      preferredVendorId: preferredVendorId ?? this.preferredVendorId,
      purchaseDescription: purchaseDescription ?? this.purchaseDescription,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      brandId: brandId ?? this.brandId,
      mpn: mpn ?? this.mpn,
      upc: upc ?? this.upc,
      isbn: isbn ?? this.isbn,
      ean: ean ?? this.ean,
      isTrackInventory: isTrackInventory ?? this.isTrackInventory,
      trackBatches: trackBatches ?? this.trackBatches,
      trackSerialNumber: trackSerialNumber ?? this.trackSerialNumber,
      trackBinLocation: trackBinLocation ?? this.trackBinLocation,
      inventoryAccountId: inventoryAccountId ?? this.inventoryAccountId,
      inventoryValuationMethod:
          inventoryValuationMethod ?? this.inventoryValuationMethod,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderTermId: reorderTermId ?? this.reorderTermId,
      isActive: isActive ?? this.isActive,
      isLock: isLock ?? this.isLock,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      createdById: createdById ?? this.createdById,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedById: updatedById ?? this.updatedById,
    );
  }
}
