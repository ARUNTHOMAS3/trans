import 'item_composition_model.dart';

class Item {
  // Primary Key
  final String? id;

  // =====================================
  // BASIC INFORMATION
  // =====================================
  final String type; // 'goods' or 'service'
  final String productName;
  final String? billingName;
  final String itemCode;
  final String? sku;
  final String unitId; // UUID reference to units table
  final String? categoryId;
  final bool isReturnable;
  final bool pushToEcommerce;

  // Tax & Regulatory
  final String? hsnCode;
  final String? taxPreference; // 'taxable', 'non-taxable', 'exempt'
  final String? intraStateTaxId;
  final String? interStateTaxId;
  final String? exemptionReason;

  // Images
  final String? primaryImageUrl;
  final List<String>? imageUrls;

  // =====================================
  // SALES INFORMATION
  // =====================================
  final double? sellingPrice;
  final String sellingPriceCurrency;
  final double? mrp;
  final double? ptr;
  final String? salesAccountId;
  final String? salesDescription;

  // =====================================
  // PURCHASE INFORMATION
  // =====================================
  final double? costPrice;
  final String costPriceCurrency;
  final String? purchaseAccountId;
  final String? preferredVendorId;
  final String? purchaseDescription;

  // =====================================
  // FORMULATION
  // =====================================
  final double? length;
  final double? width;
  final double? height;
  final String dimensionUnit;
  final double? weight;
  final String weightUnit;
  final String? manufacturerId;
  final String? brandId;
  final String? mpn; // Manufacturer Part Number
  final String? upc;
  final String? isbn;
  final String? ean;

  // =====================================
  // COMPOSITION
  // =====================================
  final bool trackAssocIngredients;
  final String? buyingRuleId;
  final String? scheduleOfDrugId;

  // =====================================
  // INVENTORY SETTINGS
  // =====================================
  final bool isTrackInventory;
  final bool trackBinLocation;
  final bool trackBatches;
  final bool trackSerialNumber;
  final String? inventoryAccountId;
  final String? inventoryValuationMethod;
  final String? storageId;
  final String? rackId;
  final int reorderPoint;
  final String? reorderTermId;
  final double? lockUnitPack;

  // =====================================
  // STATUS FLAGS
  // =====================================
  final bool isActive;
  final bool isLock;
  final bool isSalesItem;
  final bool isPurchaseItem;
  final bool isTemperatureControlled;

  // Compositions (Child Table)
  final List<ItemComposition>? compositions;

  // =====================================
  // SYSTEM FIELDS
  // =====================================
  final DateTime? createdAt;
  final String? createdById;
  final DateTime? updatedAt;
  final String? updatedById;
  final double? stockOnHand;
  final double? openingStock;
  final double? openingStockValue;
  final double? committedStock;
  final double? toBeShipped;
  final double? toBeReceived;
  final double? toBeInvoiced;
  final double? toBeBilled;

  // eCommerce Fields
  final String? storageDescription;
  final String? about;
  final String? usesDescription;
  final String? howToUse;
  final String? dosageDescription;
  final String? missedDoseDescription;
  final String? safetyAdvice;
  final List<String>? sideEffects;
  final List<String>? faqText;

  // Joined Lookup Names (Frontend Only Cache)
  final String? unitName;
  final String? categoryName;
  final String? manufacturerName;
  final String? brandName;
  final String? storageName;
  final String? inventoryAccountName;
  final String? intraStateTaxName;
  final String? interStateTaxName;
  final String? preferredVendorName;
  final String? salesAccountName;
  final String? purchaseAccountName;
  final String? rackName;
  final String? buyingRuleName;
  final String? drugScheduleName;

  Item({
    this.id,
    required this.type,
    required this.productName,
    this.billingName,
    required this.itemCode,
    this.sku,
    required this.unitId,
    this.categoryId,
    this.isReturnable = false,
    this.pushToEcommerce = false,
    this.hsnCode,
    this.taxPreference,
    this.intraStateTaxId,
    this.interStateTaxId,
    this.exemptionReason,
    this.primaryImageUrl,
    this.imageUrls,
    this.sellingPrice,
    this.sellingPriceCurrency = 'INR',
    this.mrp,
    this.ptr,
    this.salesAccountId,
    this.salesDescription,
    this.costPrice,
    this.costPriceCurrency = 'INR',
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
    this.trackAssocIngredients = false,
    this.buyingRuleId,
    this.scheduleOfDrugId,
    this.isTrackInventory = true,
    this.trackBinLocation = false,
    this.trackBatches = false,
    this.trackSerialNumber = false,
    this.inventoryAccountId,
    this.inventoryValuationMethod,
    this.storageId,
    this.rackId,
    this.reorderPoint = 0,
    this.reorderTermId,
    this.lockUnitPack,
    this.isActive = true,
    this.isLock = false,
    this.isSalesItem = true,
    this.isPurchaseItem = true,
    this.isTemperatureControlled = false,
    this.compositions,
    this.createdAt,
    this.createdById,
    this.updatedAt,
    this.updatedById,
    this.stockOnHand = 0,
    this.openingStock = 0,
    this.openingStockValue = 0,
    this.committedStock,
    this.toBeShipped,
    this.toBeReceived,
    this.toBeInvoiced,
    this.toBeBilled,
    this.storageDescription,
    this.about,
    this.usesDescription,
    this.howToUse,
    this.dosageDescription,
    this.missedDoseDescription,
    this.safetyAdvice,
    this.sideEffects,
    this.faqText,
    this.unitName,
    this.categoryName,
    this.manufacturerName,
    this.brandName,
    this.storageName,
    this.inventoryAccountName,
    this.intraStateTaxName,
    this.interStateTaxName,
    this.preferredVendorName,
    this.salesAccountName,
    this.purchaseAccountName,
    this.rackName,
    this.buyingRuleName,
    this.drugScheduleName,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id']?.toString(),
      type: json['type'] ?? 'goods',
      productName: json['product_name'] ?? '',
      billingName: json['billing_name'],
      itemCode: json['item_code'] ?? '',
      sku: json['sku'],
      unitId: json['unit_id'] ?? '',
      categoryId: json['category_id'],
      isReturnable: json['is_returnable'] ?? false,
      pushToEcommerce: json['push_to_ecommerce'] ?? false,
      hsnCode: json['hsn_code'],
      taxPreference: json['tax_preference'],
      intraStateTaxId: json['intra_state_tax_id'],
      interStateTaxId: json['inter_state_tax_id'],
      exemptionReason: json['exemption_reason'],
      primaryImageUrl: json['primary_image_url'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      sellingPrice: json['selling_price'] != null
          ? double.tryParse(json['selling_price'].toString())
          : null,
      sellingPriceCurrency: json['selling_price_currency'] ?? 'INR',
      mrp: json['mrp'] != null ? double.tryParse(json['mrp'].toString()) : null,
      ptr: json['ptr'] != null ? double.tryParse(json['ptr'].toString()) : null,
      salesAccountId: json['sales_account_id'],
      salesDescription: json['sales_description'],
      costPrice: json['cost_price'] != null
          ? double.tryParse(json['cost_price'].toString())
          : null,
      costPriceCurrency: json['cost_price_currency'] ?? 'INR',
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
      trackAssocIngredients: json['track_assoc_ingredients'] ?? false,
      buyingRuleId: json['buying_rule_id'] ?? json['buying_rule'],
      scheduleOfDrugId: json['schedule_of_drug_id'] ?? json['schedule_of_drug'],
      isTrackInventory: json['is_track_inventory'] ?? true,
      trackBinLocation: json['track_bin_location'] ?? false,
      trackBatches: json['track_batches'] ?? false,
      trackSerialNumber:
          json['track_serial'] ?? json['track_serial_number'] ?? false,
      isSalesItem: json['is_sales_item'] ?? true,
      isPurchaseItem: json['is_purchase_item'] ?? true,
      isTemperatureControlled: json['is_temperature_controlled'] ?? false,
      inventoryAccountId: json['inventory_account_id'],
      inventoryValuationMethod: json['inventory_valuation_method'],
      storageId: json['storage_id'],
      rackId: json['rack_id'],
      reorderPoint: json['reorder_point'] ?? 0,
      reorderTermId: json['reorder_term_id'],
      lockUnitPack: json['lock_unit_pack'] != null
          ? double.tryParse(json['lock_unit_pack'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      isLock: json['is_lock'] ?? false,
      compositions: json['compositions'] != null
          ? (json['compositions'] as List)
                .map((c) => ItemComposition.fromJson(c))
                .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      createdById: json['created_by_id'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      updatedById: json['updated_by_id'],
      stockOnHand: json['stock_on_hand'] != null
          ? double.tryParse(json['stock_on_hand'].toString())
          : 0,
      openingStock: json['opening_stock'] != null
          ? double.tryParse(json['opening_stock'].toString())
          : 0,
      openingStockValue: json['opening_stock_value'] != null
          ? double.tryParse(json['opening_stock_value'].toString())
          : 0,
      committedStock: json['committed_stock'] != null
          ? double.tryParse(json['committed_stock'].toString())
          : null,
      toBeShipped: json['to_be_shipped'] != null
          ? double.tryParse(json['to_be_shipped'].toString())
          : null,
      toBeReceived: json['to_be_received'] != null
          ? double.tryParse(json['to_be_received'].toString())
          : null,
      toBeInvoiced: json['to_be_invoiced'] != null
          ? double.tryParse(json['to_be_invoiced'].toString())
          : null,
      toBeBilled: json['to_be_billed'] != null
          ? double.tryParse(json['to_be_billed'].toString())
          : null,
      storageDescription: json['storage_description'],
      about: json['about'],
      usesDescription: json['uses_description'],
      howToUse: json['how_to_use'],
      dosageDescription: json['dosage_description'],
      missedDoseDescription: json['missed_dose_description'],
      unitName: json['unit']?['unit_name'],
      categoryName: json['category']?['name'],
      manufacturerName: json['manufacturer']?['name'],
      brandName: json['brand']?['name'],
      storageName:
          json['storage']?['display_text'] ?? json['storage']?['location_name'],
      rackName: json['rack']?['rack_name'],
      inventoryAccountName: json['inventoryAccount']?['user_account_name'],
      salesAccountName: json['salesAccount']?['user_account_name'],
      purchaseAccountName: json['purchaseAccount']?['user_account_name'],
      preferredVendorName: json['preferredVendor']?['display_name'],
      intraStateTaxName: json['intraStateTax']?['tax_name'],
      interStateTaxName: json['interStateTax']?['tax_name'],
      buyingRuleName: json['buyingRule']?['buying_rule'],
      drugScheduleName: json['drugSchedule']?['shedule_name'],
      safetyAdvice: json['safety_advice'],
      sideEffects: json['side_effects'] != null
          ? List<String>.from(json['side_effects'])
          : null,
      faqText: json['faq_text'] != null
          ? List<String>.from(json['faq_text'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'product_name': productName,
      if (billingName != null) 'billing_name': billingName,
      'item_code': itemCode,
      if (sku != null) 'sku': sku,
      'unit_id': unitId,
      if (categoryId != null) 'category_id': categoryId,
      'is_returnable': isReturnable,
      'push_to_ecommerce': pushToEcommerce,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (taxPreference != null) 'tax_preference': taxPreference,
      if (intraStateTaxId != null) 'intra_state_tax_id': intraStateTaxId,
      if (interStateTaxId != null) 'inter_state_tax_id': interStateTaxId,
      if (exemptionReason != null) 'exemption_reason': exemptionReason,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      'selling_price_currency': sellingPriceCurrency,
      if (mrp != null) 'mrp': mrp,
      if (ptr != null) 'ptr': ptr,
      if (salesAccountId != null) 'sales_account_id': salesAccountId,
      if (salesDescription != null) 'sales_description': salesDescription,
      if (costPrice != null) 'cost_price': costPrice,
      'cost_price_currency': costPriceCurrency,
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
      'track_assoc_ingredients': trackAssocIngredients,
      if (buyingRuleId != null) 'buying_rule_id': buyingRuleId,
      if (scheduleOfDrugId != null) 'schedule_of_drug_id': scheduleOfDrugId,
      'is_track_inventory': isTrackInventory,
      'track_bin_location': trackBinLocation,
      'track_batches': trackBatches,
      'track_serial_number': trackSerialNumber,
      // Backend DTO does not accept these flags; omit to avoid whitelist errors.
      // 'is_sales_item': isSalesItem,
      // 'is_purchase_item': isPurchaseItem,
      // 'is_temperature_controlled': isTemperatureControlled,
      'inventory_account_id': inventoryAccountId,
      'inventory_valuation_method': inventoryValuationMethod,
      'storage_id': storageId,
      'rack_id': rackId,
      'reorder_point': reorderPoint,
      'reorder_term_id': reorderTermId,
      if (lockUnitPack != null) 'lock_unit_pack': lockUnitPack,
      'is_active': isActive,
      'is_lock': isLock,
      'compositions': compositions?.map((c) => c.toJson()).toList(),
      'stock_on_hand': stockOnHand,
      'opening_stock': openingStock,
      'opening_stock_value': openingStockValue,
      'committed_stock': committedStock,
      'to_be_shipped': toBeShipped,
      'to_be_received': toBeReceived,
      'to_be_invoiced': toBeInvoiced,
      'to_be_billed': toBeBilled,
      if (storageDescription != null) 'storage_description': storageDescription,
      if (about != null) 'about': about,
      if (usesDescription != null) 'uses_description': usesDescription,
      if (howToUse != null) 'how_to_use': howToUse,
      if (dosageDescription != null) 'dosage_description': dosageDescription,
      if (missedDoseDescription != null)
        'missed_dose_description': missedDoseDescription,
      if (safetyAdvice != null) 'safety_advice': safetyAdvice,
      if (sideEffects != null) 'side_effects': sideEffects,
      if (faqText != null) 'faq_text': faqText,
    };
  }

  Item copyWith({
    String? id,
    String? type,
    String? productName,
    String? billingName,
    String? itemCode,
    String? sku,
    String? unitId,
    String? categoryId,
    bool? isReturnable,
    bool? pushToEcommerce,
    String? hsnCode,
    String? taxPreference,
    String? intraStateTaxId,
    String? interStateTaxId,
    String? exemptionReason,
    String? primaryImageUrl,
    List<String>? imageUrls,
    double? sellingPrice,
    String? sellingPriceCurrency,
    double? mrp,
    double? ptr,
    String? salesAccountId,
    String? salesDescription,
    double? costPrice,
    String? costPriceCurrency,
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
    bool? trackAssocIngredients,
    String? buyingRuleId,
    String? scheduleOfDrugId,
    bool? isTrackInventory,
    bool? trackBinLocation,
    bool? trackBatches,
    bool? trackSerialNumber,
    bool? isSalesItem,
    bool? isPurchaseItem,
    bool? isTemperatureControlled,
    String? inventoryAccountId,
    String? inventoryValuationMethod,
    String? storageId,
    String? rackId,
    int? reorderPoint,
    String? reorderTermId,
    double? lockUnitPack,
    bool? isActive,
    bool? isLock,
    List<ItemComposition>? compositions,
    double? stockOnHand,
    double? openingStock,
    double? openingStockValue,
    double? committedStock,
    double? toBeShipped,
    double? toBeReceived,
    double? toBeInvoiced,
    double? toBeBilled,
    String? storageDescription,
    String? about,
    String? usesDescription,
    String? howToUse,
    String? dosageDescription,
    String? missedDoseDescription,
    String? safetyAdvice,
    List<String>? sideEffects,
    List<String>? faqText,
    String? unitName,
    String? categoryName,
    String? manufacturerName,
    String? brandName,
    String? storageName,
    String? inventoryAccountName,
    String? intraStateTaxName,
    String? interStateTaxName,
    String? preferredVendorName,
    String? salesAccountName,
    String? purchaseAccountName,
    String? rackName,
    String? buyingRuleName,
    String? drugScheduleName,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      productName: productName ?? this.productName,
      billingName: billingName ?? this.billingName,
      itemCode: itemCode ?? this.itemCode,
      sku: sku ?? this.sku,
      unitId: unitId ?? this.unitId,
      categoryId: categoryId ?? this.categoryId,
      isReturnable: isReturnable ?? this.isReturnable,
      pushToEcommerce: pushToEcommerce ?? this.pushToEcommerce,
      hsnCode: hsnCode ?? this.hsnCode,
      taxPreference: taxPreference ?? this.taxPreference,
      intraStateTaxId: intraStateTaxId ?? this.intraStateTaxId,
      interStateTaxId: interStateTaxId ?? this.interStateTaxId,
      exemptionReason: exemptionReason ?? this.exemptionReason,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      sellingPriceCurrency: sellingPriceCurrency ?? this.sellingPriceCurrency,
      mrp: mrp ?? this.mrp,
      ptr: ptr ?? this.ptr,
      salesAccountId: salesAccountId ?? this.salesAccountId,
      salesDescription: salesDescription ?? this.salesDescription,
      costPrice: costPrice ?? this.costPrice,
      costPriceCurrency: costPriceCurrency ?? this.costPriceCurrency,
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
      trackAssocIngredients:
          trackAssocIngredients ?? this.trackAssocIngredients,
      buyingRuleId: buyingRuleId ?? this.buyingRuleId,
      scheduleOfDrugId: scheduleOfDrugId ?? this.scheduleOfDrugId,
      isTrackInventory: isTrackInventory ?? this.isTrackInventory,
      trackBinLocation: trackBinLocation ?? this.trackBinLocation,
      trackBatches: trackBatches ?? this.trackBatches,
      trackSerialNumber: trackSerialNumber ?? this.trackSerialNumber,
      isSalesItem: isSalesItem ?? this.isSalesItem,
      isPurchaseItem: isPurchaseItem ?? this.isPurchaseItem,
      isTemperatureControlled:
          isTemperatureControlled ?? this.isTemperatureControlled,
      inventoryAccountId: inventoryAccountId ?? this.inventoryAccountId,
      inventoryValuationMethod:
          inventoryValuationMethod ?? this.inventoryValuationMethod,
      storageId: storageId ?? this.storageId,
      rackId: rackId ?? this.rackId,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderTermId: reorderTermId ?? this.reorderTermId,
      lockUnitPack: lockUnitPack ?? this.lockUnitPack,
      isActive: isActive ?? this.isActive,
      isLock: isLock ?? this.isLock,
      compositions: compositions ?? this.compositions,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      openingStock: openingStock ?? this.openingStock,
      openingStockValue: openingStockValue ?? this.openingStockValue,
      committedStock: committedStock ?? this.committedStock,
      toBeShipped: toBeShipped ?? this.toBeShipped,
      toBeReceived: toBeReceived ?? this.toBeReceived,
      toBeInvoiced: toBeInvoiced ?? this.toBeInvoiced,
      toBeBilled: toBeBilled ?? this.toBeBilled,
      storageDescription: storageDescription ?? this.storageDescription,
      about: about ?? this.about,
      usesDescription: usesDescription ?? this.usesDescription,
      howToUse: howToUse ?? this.howToUse,
      dosageDescription: dosageDescription ?? this.dosageDescription,
      missedDoseDescription:
          missedDoseDescription ?? this.missedDoseDescription,
      safetyAdvice: safetyAdvice ?? this.safetyAdvice,
      sideEffects: sideEffects ?? this.sideEffects,
      faqText: faqText ?? this.faqText,
      unitName: unitName ?? this.unitName,
      categoryName: categoryName ?? this.categoryName,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      brandName: brandName ?? this.brandName,
      storageName: storageName ?? this.storageName,
      inventoryAccountName: inventoryAccountName ?? this.inventoryAccountName,
      intraStateTaxName: intraStateTaxName ?? this.intraStateTaxName,
      interStateTaxName: interStateTaxName ?? this.interStateTaxName,
      preferredVendorName: preferredVendorName ?? this.preferredVendorName,
      salesAccountName: salesAccountName ?? this.salesAccountName,
      purchaseAccountName: purchaseAccountName ?? this.purchaseAccountName,
      rackName: rackName ?? this.rackName,
      buyingRuleName: buyingRuleName ?? this.buyingRuleName,
      drugScheduleName: drugScheduleName ?? this.drugScheduleName,
    );
  }
}
